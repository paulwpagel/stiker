$: << File.expand_path(File.dirname(__FILE__) + "/../lib")
require "rubygems"
require "daemons"
require "simple_logger"

CONFIG = {:rinda_port => 6683, :rinda_host => "localhost"} unless defined?(CONFIG)

$logger = SimpleLogger.new