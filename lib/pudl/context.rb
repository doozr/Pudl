require_relative './entity'
require_relative './logging'

module Pudl

  # Basic key/value store with synchronisation
  #
  class Context
    include Logging
    include Extras

    class Store
      include Logging
      include Extras

      attr_reader :values, :exit_code

      def initialize
        @values = {}
        @exit_code = 0
        @abort = false
      end

      def abort?
        @abort
      end

      def abort code=1
        @exit_code = code
        @abort = true
      end

      def set k, v=nil, &b
        unless k.is_a? Symbol
          raise ArgumentError, "Context keys must be symbols"
        end

        if !v.nil? && !b.nil?
          raise ArgumentError, "Cannot specify a value and a block in a single property"
        end

        if b
          @values[k] = instance_exec @values[k], &b
        else
          @values[k] = v
        end
      end

      def get k
        @values[k]
      end

    end

    attr_reader :values, :mutex

    def initialize
      @store = Store.new
      @mutex = Mutex.new
    end

    def abort?
      @store.abort?
    end

    def abort code=1
      mutex.synchronize do
        @store.abort code
      end
    end

    def exit_code
      @store.exit_code
    end

    def values
      @store.values
    end

    # Set a key/value
    #
    def set k, v=nil, &b
      mutex.synchronize do
        @store.set k, v, &b
      end
    end

    # Get the value of a key
    #
    def get k
      mutex.synchronize do
        @store.get k
      end
    end

  end

end
