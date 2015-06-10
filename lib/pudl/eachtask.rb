require_relative './basetask'
require_relative './task'

module Pudl

  # A task that generates other tasks at runtime based
  # on a source array
  #
  class EachTask < BaseTask

    attr_reader :basename
    attr_accessor :source, :task

    def initialize name
      unless name.is_a? Symbol
        raise ArgumentError, "EachTask name #{name} must be a symbol"
      end
      super :"#{name}_generator"
      @basename = name
    end

    class Dsl < BaseTask::Dsl

      @@actions = {}

      property_single :source do |v|
        entity.source = v
      end

      def task &b
        if !b
          raise ArgumentError, "Task block must be provided"
        end
        entity.task = b
      end

    end

    class Runner < BaseTask::Runner

      def run *args
        __generate_tasks(value_of entity.source)
      end

      def dry_run *args
        logger.debug "#{entity.name}: Create tasks for each of #{pretty entity.source}"
        __generate_tasks [:dummy]
      end

      private

      def __generate_tasks values
        generator_name = entity.name

        # Only skip generation of new tasks if skip? is true
        if skip?
          logger.info "#{entity.name}: Skipping task generation because only_if #{pretty entity.only_if} is false"
          tasks = []
        else
          tasks = values.each_with_index.map do |value, index|
            name = :"#{entity.basename}_#{index}"
            logger.debug "#{entity.name}: Create task #{pretty name} for #{pretty value}"

            # Generate the task and force it to be dependent on this generator task
            task = Task.parse name, value, index, &entity.task
            task.after << generator_name

            task
          end
        end

        # Always generate the end task so that dependent tasks will work
        endtask = Task.parse entity.basename do
          after generator_name, *(tasks.map &:name)
        end

        tasks << endtask
      end

    end

    def self.add_actions actions={}
      Dsl.add_actions actions
    end

    dsl_class Dsl
    runner_class Runner

  end

end
