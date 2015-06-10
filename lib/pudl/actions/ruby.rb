require_relative '../baseaction'

module Pudl

  module Actions

    # Very simple action that allows arbitrary code blocks
    #
    class RubyAction < BaseAction

      attr_accessor :code

      def initialize name
        super
      end

      class Dsl < BaseAction::Dsl

        def code &b
          unless b
            raise ArgumentError, "No code block supplied"
          end
          entity.code = b
        end

      end

      class Runner < BaseAction::Runner

        def run *args
          if entity.code
            context.instance_exec &entity.code
          end
        end

        def dry_run *args
          logger.info "Would execute code"
        end

      end

      dsl_class Dsl
      runner_class Runner

    end

  end

end

