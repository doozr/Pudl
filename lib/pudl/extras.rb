module Pudl
  module Extras

    @@methods = {}

    def method_missing name, *args, &block
      if @@methods[name]
        instance_exec *args, &@@methods[name]
      else
        super
      end
    end

    def self.add_method name, &block
      if @@methods[name]
        raise ArgumentError, "Refusing to redefine method #{name}"
      end
      @@methods[name] = block
    end

    def self.clear_methods
      @@methods = {}
    end

  end
end
