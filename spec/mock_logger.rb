
class MockLogger
  attr_reader :infos, :errors, :fatals, :debugs
  attr_accessor :verbose

  def initialize(verbose = false)
    @verbose = verbose
    clear
  end

  def info(message, hash ={})
    @infos << message
    puts "INFO: #{message}" if @verbose
  end

  def error(message, hash ={})
    @errors << message
    puts "ERROR: #{message}" if @verbose
  end

  def fatal(message, hash ={})
    @fatals << message
    puts "FATAL: #{message}" if @verbose
  end

  def debug(message, hash ={})
    @debugs << message
    puts "DEBUG: #{message}" if @verbose
  end
    
  alias :pb_info :info
  alias :pb_error :error
  alias :pb_fatal :fatal
  
  def pb_exception(e, hash={})
    error("#{e.message}\n#{e.backtrace.join('\n')}", hash)
  end
  
  def clear
    @infos = []
    @errors = []
    @fatals = []
    @debugs = []
  end
end
