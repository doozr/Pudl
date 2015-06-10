require_relative "./pipeline"

module Pudl

  class Parser

    def parse filename
      instance_eval File.read(filename), filename
      @pipeline
    end

    def pipeline name, &block
      @pipeline = Pipeline.parse name, &block
    end

    def self.parse filename
    end

  end

end
