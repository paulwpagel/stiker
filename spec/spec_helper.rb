$: << File.expand_path(File.dirname(__FILE__) + "/../lib")
require 'rubygems'
require 'rspec'
require "mock_rinda_client"
require "mock_logger"


$logger = MockLogger.new
CONFIG = {} if not defined? CONFIG
CONFIG[:rinda_host] = "localhost"
CONFIG[:rinda_port] = 9123
CONFIG[:email_host] = "your.smtpserver.com" 
CONFIG[:email_port] = "25"
CONFIG[:email_domain] = "smtpserver.com"
CONFIG[:error_email_to] = "error_to,error_to_too"
CONFIG[:error_email_from] = "error_from"
CONFIG[:monitor_ping_grace_period] = 2
CONFIG[:monitor_max_failed_pings] = 2
CONFIG[:rinda_shutdown_wait] = 0
CONFIG[:monitor_unsubscribe_grace_period] = 0

