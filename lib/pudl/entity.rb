require_relative './logging'
require_relative './property_types'
require_relative './extras'

module Pudl

  module DslClassAccessor
    @dsl_class = nil
    def get_dsl_class
      @dsl_class
    end

    def dsl_class c
      @dsl_class = c
    end
  end

  module RunnerClassAccessor
    @runner_class = nil
    def get_runner_class
      @runner_class
    end

    def runner_class c
      @runner_class = c
    end
  end

  # Base class of all entities in the Pudl universe
  #
  class Entity
    include Logging
    extend DslClassAccessor
    extend RunnerClassAccessor

    attr_reader :name
    attr_accessor :only_if

    def initialize name
      @name = name
      @only_if = true
    end

    # Base class of all Dsl implementations in the Pudl universe
    class Dsl
      include Logging
      include PropertyTypes
      include Extras

      attr_reader :entity

      def initialize entity
        @entity = entity
      end

      property_single :only_if do |v|
        entity.only_if = v
      end

    end

    # Base class of all Runner implementations in the Pudl universe
    class Runner
      include Logging

      attr_reader :entity, :context

      def initialize entity, context=nil
        @entity = entity
        @context = context || Pudl::Context.new
      end

      # Execute the entity
      #
      def run *args
        raise "Not implemented: #{self.class.name}::run"
      end

      # Display what would happen if the entity was run
      #
      def dry_run *args
        raise "Not implemented: #{self.class.name}::dry_run"
      end

      # Return true if the only_if property evaluates to a falsey
      # value, else return false
      def skip?
        !value_of(entity.only_if)
      end

      # Dereference a value
      #
      # * If a symbol is passed, attempt to retrieve it from the context
      # * If a callable is passed, call it and return the result
      # * Otherwise return untouched
      #
      def value_of v, *args
        if v.is_a? Symbol
          context.get v
        elsif v.respond_to? :call
          context.instance_exec *args, &v
        else
          v
        end
      end

      # Reference a value by either passing it to a block
      # or setting it in the context, depending on the type
      # of the key
      def yield_to k, *args
        if k.is_a? Symbol
          if args.length > 1
            logger.debug "Cannot assign #{args.length} values to context key; using '#{args[0]}', discarding '#{args.join "', '"}'"
          end
          context.set k, args[0]
        elsif k.respond_to? :call
          context.instance_exec *args, &k
        else
          raise ArgumentError, "Invalid out property, #{k.class.name} should be symbol or block"
        end
      end

      # Pretty-print a value
      #
      # * If a callable is passed return <code>
      # * Otherwise return the result of the inspect method
      #
      def pretty v
        if v.respond_to? :call
          "<code>"
        else
          v.inspect
        end
      end

    end

    # Parse a block and inject the results into a new entity,
    # then return the entity
    #
    def self.parse name, *args, &block
      entity = self.new name

      dsl = get_dsl_class.new entity
      dsl.instance_exec *args, &block
      entity
    end

    # Create and return an instance of the runner for the entity
    #
    def runner context=nil
      self.class.get_runner_class.new self, context
    end

  end

end
