require_relative './actions/context'
require_relative './actions/ruby'

module Pudl

  module Actions

    def self.get_actions
      {
        context: ContextAction,
        ruby:    RubyAction
      }
    end

  end

end
