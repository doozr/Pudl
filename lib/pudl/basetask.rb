require_relative './entity'

module Pudl

  # The basis of all tasks
  #
  class BaseTask < Entity

    attr_accessor :after

    def initialize name
      unless name.is_a? Symbol
        raise ArgumentError, "Task name #{name} must be a symbol"
      end

      super
      @after = []
    end

    class Dsl < Entity::Dsl

      property_multi_static :after do |v|
        entity.after = v
      end

    end

    # Placeholder for completeness
    class Runner < Entity::Runner
    end

    dsl_class Dsl
    runner_class Runner

  end

end

