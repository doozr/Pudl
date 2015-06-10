module Pudl

  module PropertyTypes

    def self.included base
      base.extend ClassMethods
    end

    module ClassMethods

      # Define a DSL property that accepts a single value
      def property_single_static name, &block
        send :define_method, name do |v=nil, &b|
          if !b.nil?
            raise ArgumentError, "property_single_static properties do not support blocks"
          end
          instance_exec v, &block
        end
      end

      # Define a DSL property that accepts a single value
      # or a block. If no value specified, pass the block
      def property_single name, &block
        send :define_method, name do |v=nil, &b|
          if !v.nil? && !b.nil?
            raise ArgumentError, "Cannot specify a value and a block in a single property"
          end
          v = b if v.nil?
          instance_exec v, &block
        end
      end

      # Define a DSL property that accepts multiple values
      # and receives them as an array
      def property_multi_static name, &block
        send :define_method, name do |*args, &b|
          if !b.nil?
            raise ArgumentError, "property_multi_static properties do not support blocks"
          end
          instance_exec args, &block
        end
      end

      # Define a DSL property that accepts multiple values
      # and receives them as an array, or a block that
      # returns an array when called
      def property_multi name, &block
        send :define_method, name do |*args, &b|
          if !args.empty? && b
            raise ArgumentError, "Cannot specify a value and a block in a multi property"
          end
          args = b if args.empty? && b
          instance_exec args, &block
        end
      end

      # Define a DSL property that accepts two arguments,
      # a key and a value
      def property_keyval_static name, &block
        send :define_method, name do |k, v=nil, &b|
          if !b.nil?
            raise ArgumentError, "property_keyval_static properties do not support blocks"
          end
          if !k.is_a? Symbol
            raise ArgumentError, "Key must be a symbol in a keyval_static property"
          end
          instance_exec k, v, &block
        end
      end

      # Define a DSL property that accepts two arguments,
      # a key and a value, or one argument and a block
      def property_keyval name, &block
        send :define_method, name do |k, v=nil, &b|
          if !v.nil? && !b.nil?
            raise ArgumentError, "Cannot specify a value and a block in a keyval property"
          end
          if !k.is_a? Symbol
            raise ArgumentError, "Key must be a symbol in a keyval property"
          end
          v = b if v.nil?
          instance_exec k, v, &block
        end
      end

      # Define a DSL property that receives a value, either
      # into a context key or a block. Only symbols and blocks
      # are permissible here.
      def property_out name, &block
        send :define_method, name do |v=nil, &b|
          if !v.nil? && !b.nil?
            raise ArgumentError, "Cannot specify a key and a block in an out property"
          end
          if v.nil? && b.nil?
            raise ArgumentError, "Must specify a symbol or a block in an out property"
          end
          if v && !v.is_a?(Symbol)
            raise ArgumentError, "Only symbols and blocks allowed for out property"
          end
          v = b if v.nil?
          instance_exec v, &block
        end
      end

    end

  end

end
