![Pudl](pudl-logo.png)

# Pudl - Pipeline Unified Description Language #

*(Yes, it's a backronym)*

The Pipeline Unified Description Language provides a simple way to script
pipelines of work using disparate tools into discrete tasks with unified
syntax that can be run in a managed way. The language is extensible and
allows for many different custom behaviours to be injected at run-time so
it can be configured precisely to the job at hand.

# Getting Started

Pudl pipelines are defined by a very simple, Ruby-esque DSL that should be
familiar with anyone who has used a Ruby DSL before. There are a handful of
simple constructs already created to get your first pipeline started.

``` ruby
require 'pudl'

pipeline = Pudl.parse "mypipeline.rb"
```

``` ruby
pipeline 'My Pipeline' do

  task :first_task do
    # Put actions in here
  end

  task :second_task do
    after :first_task
  end

  task :third_task do
    after :first_task
  end

  task :fourth_task do
    after :first_task, :third_task
  end

  on_error do
    # Put error cleanup actions here
  end

end
```

This pipeline will do absolutely nothing, but it will let us explore some
important aspects of the system.

## Running the Pipeline

Running the pipeline is achieved by creating a pipeline runner instance
with a new runtime context and running it.

``` ruby
runner = pipeline.runner
runner.run
```

The #run method will calculate the optimal ordering of tasks to ensure
dependencies are satisfied (more on those later) and execute all the tasks,
parallelising where possible.

## Dry Run

If you want to find out what the pipeline would do, but not actually do it,
use the #dry\_run method instead.

``` ruby
runner = pipeline.runner
runner.dry_run
```

This will output what the task would have done, and what values it would
have used, so you can ensure the ordering is correct.

# Creating An Action

All actions are created as subclasses of the Pudl::BaseAction class, and
contains a Dsl and Runner class that handles parsing and execution
respectively. A basic task that does nothing but output its name may look
like this:

``` ruby
class MeAction < Pudl::BaseAction

  # Define attributes of this action
  attr_accessor :surname

  # Define the DSL parser for this action
  class Dsl < BaseAction::Dsl

    # There are many types of propery
    property_single :surname do |n|

      # entity refers to an instance of MeAction
      entity.surname = n
    end
  end

  # Define the Runner class for this action
  class Runner < BaseAction::Runner

    # The run method should actually perform the action
    def run
      # entity refers to an instance of MeAction
      # all entities have a name
      puts "#{entity.name} #{entity.surname}"
    end

    # Perform a dry run; don't actually do anything but pring
    def dry_run
      puts "Output name: #{entity.name} and surname: #{entity.surname}"
    end
  end

  # Set the DSL and Runner classes for this action
  dsl_class Dsl
  runner_class Runner

end
```

Including this action in the DSL means adding it to the Pudl DSL:

``` ruby
Pudl::add_actions( { me: MeAction } )
```

It can then be used in a pipeline:

``` ruby
pipeline "My Pipeline" do
  task :first_task do
    me "Joe" do
      surname "Bloggs"
    end
  end
end
```

Running the pipeline results in the output `Joe Bloggs`, as you might expect.

# Context

Each Pudl Runner class accepts a context argument that should be an
instance of Pudl::Context. This class provides a way to share state between
tasks and actions in the form of a key value store.

## Use in actions

Actions derived from Pudl::BaseAction have access to the context from within
their own methods. This means that it is feasible build an action like
this:

``` ruby
pipeline "My Pipeline" do
  task :my_task

    # Hypothetical database access action
    db "SELECT id, name FROM table WHERE column = value" do
      action :select_one

      # The hypothetical #field method retrieves a column and puts it in
      # a named context variable
      field "name", :name
    end
  end
end
```

## Use in blocks

Most attributes accept context keys as parameters and will do something
clever with them, either reading a named value from the context at runtime
else writing a new value to the given key. These attributes can also
take a block of code.

If the attribute requires a value, the return value of the block is used,
and if the attribute provides a value it is passed to the block. In
addition, the methods #get and #set can be used to access the context.

``` ruby
pipeline "My Pipeline" do
  task :my_task do

    db "SELECT id, name FROM table WHERE column = value" do
      action :select_one
      field "name" do |value|
        set :name, value.capitalize
      end
    end

    context do
      get :name do |name|
        # You can use the ruby logger from here too
        logger.info "The capitalised name is #{name}"
      end
    end
  end
end

## Additional Context

It is possible to pass additional data to the context to make it available
to the pipeline. This is done by accessing the context before calling #run.

``` ruby
pipeline = Pudl::parse "pipeline.rb"
runner = pipeline.runner

# Set some context
runner.context.set :name, "Joe"

# Get all values in the context
runner.context.values.each do |k, v|
  puts "#{k} => #{v}"
end
```

# Error Handling

Error handling in Pudl is largely based around cleaning up when an error
occurs rather than preventing or recovering from them. Of course, being
Ruby underneath, the normal error handlers can be used if you prefer, but
there are some built in constructs to assist in this regard.

## Error Handler in a Pipeline

At the Pudl::Pipeline level, tasks are run and may raise errors due to many
external factors. It is possible to add an error handler task that cleans
up anything that might get left behind in an error situatation. This is
done with the `on_error` command.

``` ruby
pipeline "My Pipeline" do

  task :setup do
    db "create_table.sql" do
      action :execute_file
    end

    db "fixture.sql" do
      action :import_from_file
      table "staging"
    end
  end

  task :export do
    db "procedure.sql" do
      action :execute_file
    end
  end

  on_error do
    db "DROP TABLE staging" do
      action :execute
    end
  end
end
```

In this contrived example, a file full of data is imported and then a
procedure is run on it. If something goes wrong, the staging table needs to
be removed. The task described by the `on_error` command does just that,
and is only run if something raises an error and forces the pipeline to
terminate.

## Error Handler in an Action

Consider our previous contrived example. This time, instead of deleting the
staging table, it should be left for future debugging. However, if the
import fails the pipeline should exit gracefully because there is nothing
to do.

``` ruby
Pudl::Pipeline.new "My Pipeline", Pudl::Context.new() do

  task :setup do
    db "create_table.sql" do
      action :execute_file
    end

    db "fixture.sql" do
      action :import_from_file
      table "staging"
      on_error :exit
    end
  end

  task :export do
    db "procedure.sql" do
      action :execute_file
    end
  end
end
```

The `on_error` command within an action takes on a different meaning. It
allows a flag to be set to tell it how to behave. The possible options are:

`:raise`
: Raise an error (this is the default)

`:exit`
: Exit the pipeline cleanly

`:continue`
: Ignore the error and continue

# And more!

``` ruby
\#TODO Add more documentation ...
```

* built in actions
  * context
  * ruby
* extending the DSL with custom methods
* understanding locking in the context
* aborting pipeline execution sanely

