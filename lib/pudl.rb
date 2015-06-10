require_relative './pudl/logging'
require_relative './pudl/context'
require_relative './pudl/pipeline'
require_relative './pudl/parser'
require_relative './pudl/extras'
require_relative './pudl/actions'

module Pudl

  def self.add_method name, &block
    Pudl::Extras.add_method name, &block
  end

  def self.clear_methods
    Pudl::Extras.clear_methods
  end

  def self.add_actions actions={}
    Pudl::Task::Dsl.add_actions actions
  end

  def self.clear_actions
    Pudl::Task::Dsl.clear_actions
  end

  def self.logger= logger
    Pudl::Logging.logger = logger
  end

  def self.parse filename
    Pudl::Parser.new.parse filename
  end

  add_actions Pudl::Actions.get_actions

end
