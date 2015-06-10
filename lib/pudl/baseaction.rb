require_relative './entity'

module Pudl

  # Base class for all actions
  #
  class BaseAction < Entity

    class Dsl < Entity::Dsl
    end

    class Runner < Entity::Runner

      def run *args
        logger.warn "#{self.class.name} has no run behaviour"
      end

      def dry_run *args
        logger.info entity.inspect
      end

    end

    dsl_class Dsl
    runner_class Runner

  end

end

