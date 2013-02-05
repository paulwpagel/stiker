require 'rinda_client'
require 'timeout'
require 'socket'

module Rinda
  # Subclasses may also define the following methods as needed:
  # do_standard_preparation - pre-run standard setup code
  # prepare - pre-run setup code specific to the rindlet type
  # finish_up - post-run cleanup code
  # rinda_client - provide a specific <tt>Rinda::RindaClient</tt>

  class Rindlet

    attr_accessor :rinda_client
    attr_accessor :pulse
    attr_accessor :number
    attr_accessor :app_id
    attr_accessor :error_topic    
    attr_accessor :tuple

    # Creates a Rindlet instance identified by number
    def initialize(number, pulse = 5)
      @number = number
      @pulse = pulse
      @running = false
      @retry_delay = CONFIG[:rindlet_retry_delay] || 3600
      @error_topic = "error"

    end

    def name
      @name = "#{self.class.name.split('::')[-1]}_#{number}" if not @name
      return @name
    end

    def startup
      $logger.info "#{name} warming up..."
      prepare
      $logger.info "#{name} started."
    end

    def shutdown
      finish_up
      $logger.info "#{name} stopped."
    end

    def start
      @running = true
      startup
      enter_loop
      shutdown
    end

    def stop
      $logger.info "#{name} winding down..."
    end

    protected #############################################

    def prepare
    end

    def run
    end

    def finish_up
    end
    
    def rinda_client
      @rinda_client ||= RindaClient.new
    end

    def with_tuple(tuple, pulse = @pulse, &block)
      @tuple = take_with_timeout(tuple, pulse)
      if @tuple
        @is_loaded_cycle = true if !@pinging
        begin
          yield(@tuple) if block_given?
        rescue Exception => e
          standard_error_response(@tuple[0], @tuple[2], e, @tuple)
        end
      end
    end
    
    # def read_tuple(tuple, pulse = @pulse, &block)
    #   @tuple = rinda_client.read(tuple, 0)
    #   if @tuple
    #     @is_loaded_cycle = true if !@pinging
    #     begin
    #       yield(@tuple) if block_given?
    #     rescue Exception => e
    #       standard_error_response(@tuple[0], @tuple[2], e, @tuple)
    #     end
    #   end
    # end
    

    def standard_error_response(context, task, e, tuple)
      log_exception(e)
      @running = false
    end

    private ###############################################

    def take_with_timeout(wildcard_tuple, timeout)
      rinda_client.take(wildcard_tuple, timeout)
    end

    def take_is_possible?(wildcard_tuple)
      rinda_client.read(wildcard_tuple, 0)
    end

    def enter_loop
      begin
        while @running
          run
        end
      rescue Exception => ex
        log_exception(ex)
      end
    end

    def do_loop
      raise "do_loop must be given a block specifying a stop condition" unless block_given?
      begin
        run while yield
      rescue Exception => ex
        log_exception(ex)
      end
    end

    def log_exception(e, log_backtrace=true)
      $logger.error "Rindlet Error in #{self.class}: #{e}"
      $logger.error e.backtrace.join("\n") if log_backtrace
    end


  end
end
