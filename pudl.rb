require 'logger'
require_relative './lib/pudl'

logger = Logger.new STDOUT
logger.level = Logger::INFO
Pudl.logger = logger

c = {
  pirate: "YARR",
  ninja: "..."
}

Pudl.add_method :config do |key|
  c[key] || "NO"
end

Pudl.add_method :params do
  ARGV
end

# Simple sample pipeline of madness
pipeline = Pudl.parse "sample.rb"

runner = pipeline.runner
puts "\n Dry Run \n"
runner.dry_run
puts "\n Run \n"
runner.run


runner.context.values.each do |k, v|
  puts "#{k} => #{v}"
end
