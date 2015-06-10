require_relative '../baseaction'

module Pudl

  module Actions

    # Very simple action that facilitates bulk-setting and getting of context values
    #
    class ContextAction < BaseAction

      attr_accessor :values, :requests

      def initialize name
        super
        @values = {}
        @requests = {}
      end

      class Dsl < BaseAction::Dsl

        property_keyval :set do |k, v|
          entity.values[k] = v
        end

        property_keyval :get do |k, v|
          unless v.respond_to? :call
            raise ArgumentError, "Context get must be passed a block"
          end
          entity.requests[k] = v
        end

      end

      class Runner < BaseAction::Runner

        def run *args
          entity.values.each do |k, v|
            if v.respond_to? :call
              context.set k, &v
            else
              context.set k, value_of(v)
            end
            logger.debug "Set #{pretty k} to #{pretty(context.get k)}"
          end

          entity.requests.each do |k, b|
            v = context.get(k)
            logger.debug "Requested value of #{pretty k} is #{pretty v}"
            b.call v
          end
        end

        def dry_run *args
          entity.values.each do |k, v|
            logger.info "Would set #{pretty k} to #{pretty v}"
          end
          entity.requests.each do |k, v|
            logger.info "Would retrieve #{pretty k}"
          end
        end

      end

      dsl_class Dsl
      runner_class Runner

    end

  end

end
