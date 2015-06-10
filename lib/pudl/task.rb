require_relative './basetask'

module Pudl

  # A task with dependencies
  #
  class Task < BaseTask

    attr_accessor :actions, :on_error

    def initialize name
      super
      @actions = []
    end

    class Dsl < BaseTask::Dsl

      @@actions = {}

      def on_error &b
        entity.on_error = b
      end

      def method_missing method, name=nil, *args, &block
        if @@actions.has_key? method
          name ||= "#{entity.name}:#{method}"
          action = @@actions[method].parse name, *args, &block
          entity.actions.push action
        else
          super
        end
      end

      def respond_to? method
        @@actions.has_key? method || super
      end

      def self.add_actions actions={}
        @@actions = @@actions.merge actions
      end

      def self.clear_actions
        @@actions = {}
      end

    end

    class Runner < BaseTask::Runner

      def run *args
        if skip?
          logger.info "#{entity.name}: Skipping task because only_if #{pretty entity.only_if} is false"
          return []
        end

        logger.debug "#{entity.name}: Running #{entity.actions.count} actions"
        begin
          entity.actions.each do |action|
            next if context.abort?

            runner = action.runner(context)
            if runner.skip?
              logger.info "#{entity.name}: Skipping action #{pretty action.name} because only_if #{pretty action.only_if} is false"
            else
              runner.run
            end
          end
        rescue => e
          if entity.on_error
            context.instance_exec e, &entity.on_error
          else
            raise
          end
        end
        []
      end

      def dry_run *args
        logger.debug "#{entity.name}: Not running #{entity.actions.count} actions"
        entity.actions.each do |action|
          action.runner(context).dry_run
        end
        []
      end

    end

    dsl_class Dsl
    runner_class Runner

  end

end
