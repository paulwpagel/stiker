require 'log4r'
require 'log4r/outputter/datefileoutputter'
require 'socket'
require 'fileutils'

module Logging
  
  def self.create_unique_logger(name, dir)
    create_logger(name, "#{name}_#{host}_#{pid}.log", File.join(dir, "logs"))
  end
  
  def self.create_unique_machine_logger(name, dir)
    create_logger(name, "#{name}_#{host}.log", File.join(dir, "logs"))
  end
  
  def self.create_shared_logger(name, dir)
    create_logger(name, "#{name}.log", File.join(dir, "logs"))
  end

  def self.create_logger(name, filename, dir)
    logger = Log4r::Logger.new(name)
    logger.level = Log4r::DEBUG
    FileUtils.mkdir_p(dir)
    outputter = Log4r::DateFileOutputter.new(name, {:filename => filename, :trunc => false, :date_pattern => date_pattern, :dirname => dir})
    outputter.formatter = Log4r::PatternFormatter.new(:pattern => "[%l][#{host}][%c][#{pid}][%d] :: %m")
    logger.add(name)
    return logger
  end
  
  def self.pid
    Process.pid
  end
    
  def self.host
    Socket.gethostname
  end
  
  def self.date_pattern
    '%Y-%m-%d'
  end
end

module Log4r
  class Logger

    [:debug, :info, :warn, :error, :fatal].each do |m|
      define_method("pb_#{m}") { |message, *optional_args| send(m, log_message(message, optional_args[0]||{})) }
    end

    def pb_exception(exception, hash={})
      message = "#{exception.class}: #{exception}\n#{exception.backtrace.join("\n")}"
      pb_error(message, hash)
    end
    
    def log_message(message, hash)
      return "#{identifier_for(hash)} #{message}"
    end
    
    def identifier_for(hash)
      identifier = ""
      keys = hash.keys.sort { |a,b| a.to_s <=> b.to_s }
      keys.each do |key|
        value = hash[key]
        identifier += "[#{key.to_s}=#{value}]"
      end
      return identifier
    end
  end
end

