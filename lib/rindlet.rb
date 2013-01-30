require 'rinda_client'
# MDS - Need for errors - at least on some machines
require 'timeout'
require 'socket'
require 'load_calculator'

module Rinda
  # Rindlets are like threads. They can be started, stopped and checked to see if they're running. <tt>Rinda::Rindlet</tt>
  # is abstract and subclasses should minimally define a run method to perform the task of the rindlet.
  #
  # Subclasses may also define the following methods as needed:
  # do_standard_preparation - pre-run standard setup code
  # prepare - pre-run setup code specific to the rindlet type
  # finish_up - post-run cleanup code
  # rinda_client - provide a specific <tt>Rinda::RindaClient</tt>
  #
  # Example:
  #
  #
  #    class SimpleRindlet < Rinda::Rindlet
  #
  #      def initialize(number)
  #        super(number)
  #      end
  #
  #      def prepare
  #        # put tuple 0 the tuplespace
  #        rinda_client.write(["simple", "0"])
  #      end
  #
  #      def run
  #        # read tuple n and write tuple n+1
  #        with_tuple(["simple"]) do |tuple|
  #          rinda_client.write(["simple", (tuple.last.to_i + 1).to_s], 10)
  #        end
  #      end
  #
  #    end
  #
  #
  #    CONFIG = {:rinda_port => 3004, :rinda_host => "localhost"} unless defined?(CONFIG)
  #    SimpleRindlet.new(1).start
  #
  #
  class Rindlet
    # thread local variable name that is true when a rindlet thread should not be interrupted
    IS_DOING_SOMETHING_USEFUL = :rindlet_is_doing_something_useful

    # Class constants enumerating list of network errors
    NetworkErrors = [::Timeout::Error, ::Errno::EPIPE, ::SocketError, ::Errno::ECONNREFUSED]

    # The <tt>Rinda::RindaClient</tt> used for takes
    attr_accessor :rinda_client
    # The amount of time to wait for the rinda server to respond to a take
    attr_accessor :pulse
    # Instance number for this type of rindlet
    attr_accessor :number
    # Identifies the application in an error message
    attr_accessor :app_id
    # Identifies the error topic in an error message
    attr_accessor :error_topic
    # Identifies the set of exceptions this rindlet can recover from
    attr_reader :recoverable_exceptions
    # The <tt>LoadCalculator</tt> used by this rindlet
    attr_reader :load_calculator
    # Timeout value for reply to a ping
    attr_accessor :pong_timeout
    
    attr_accessor :tuple

    # Creates a Rindlet instance identified by number
    def initialize(number, pulse = 5)
      @number = number
      @pulse = pulse
      @running = false
      @recoverable_exceptions = []
      @retry_delay = CONFIG[:rindlet_retry_delay] || 3600
      @error_topic = "error"
      @load_calculator = LoadCalculator.new(self)
      @pong_timeout = CONFIG[:rindlet_monitor_pong_timeout] || 120
    end

    # Returns the name of this rindlet
    def name
      @name = "#{self.class.name.split('::')[-1]}_#{number}" if not @name
      return @name
    end


    def startup
      $logger.info "#{name} warming up..."
      do_standard_preparation
      prepare
      $logger.info "#{name} started."
    end

    def shutdown
      finish_up
      $logger.info "#{name} stopped."
    end

    # Runs the rindlet. Performs pre-run preparation, responds to any pings, calls run, and calls post-run cleanup
    #
    # @param thread_per_request [Boolean] tells whether to use thread_per_request model
    #
    def start
      @running = true
      startup
      subscribe_to_monitor
      enter_loop
      shutdown
    end


    # TODO ejp remove start, stop, subscribe_to_monitor, enter_loop, @running, @load_calculator, @pong_timeout once we move to new launching mechanism

    # Starts the rindlet loop in a process or thread and optionally using thread_per_request model (depending on
    # options). Will return the rindlet thread that was started.
    #
    # @param options [Hash] may contain any of the following:
    #     :thread_per_request => [Boolean] tells whether to use thread_per_request model
    #
    def start_thread(options={})
      @thread_per_request = !!options[:thread_per_request]
      # creates the main thread that will do the loop and spawn any handler threads
      return @rindlet_thread = Thread.new do
        Thread.current[:running] = true
        startup
        do_loop { Thread.current[:running] }
        shutdown
      end
    end

    # Returns true if the rindlet is currently running
    def running?
      return @rindlet_thread ? @rindlet_thread[:running] : @running
    end

    # Stops execution of the rindlet
    def stop
      unsubscribe_to_monitor
      $logger.info "#{name} winding down..."
      @rindlet_thread ? @rindlet_thread[:running] = false : @running = false
    end

    # Stops execution of the rindlet
    # NOTE: this method assumes each rindlet instance is running in it's own thread group.
    # This method must be called from within the proper thread group in order for it to log correctly
    # This method does not support legacy @running mechanism
    def stop_asap
      $logger.info "#{name} shutting down now ..."
      if @rindlet_thread
        @rindlet_thread[:running] = false
        # wait for any active threads to finish processing the tuple and kill the main rindlet thread
        @rindlet_thread.kill unless @rindlet_thread.group.list.any? { |t| t[IS_DOING_SOMETHING_USEFUL] }
      end
    end


    # add <tt>exceptions_types</tt> to the set of exceptions this rindlet can recover from
    def recover_from(*exceptions_types)
      exceptions_types.each do |exception_type|
        @recoverable_exceptions << exception_type if not @recoverable_exceptions.include?(exception_type)
      end
    end

    protected #############################################


    # Executes pre-run standard setup code
    def do_standard_preparation
      # should be overridden by children
    end

    # Executes pre-run setup code specific to the rindlet type
    def prepare
      # should be overridden by children
    end

    # Executes the rindlet's main task
    def run
      # should be overridden by children
    end

    # Executes post-run cleanup code
    def finish_up
      # should be overridden by children
    end

    # Override to provide a specific <tt>Rinda::RindaClient</tt>
    def rinda_client
      @rinda_client ||= RindaClient.new
    end

    # takes the given tuple from the tuplespace and yields it to the given block. Optional timeout
    # determines how long to wait to connect to the rinda server before failing
    #
    # Example:
    #
    #    with_tuple(["some_context", "some_request", "some_task", "some_app_id"]) do |tuple|
    #      # do something
    #    end
    #
    #
    def original_with_tuple(tuple, pulse = @pulse)
      @tuple = take_with_timeout(tuple, pulse)
      if @tuple
        Thread.current[IS_DOING_SOMETHING_USEFUL] = true
        @is_loaded_cycle = true if !@pinging
        begin
          yield(@tuple) if block_given?
        rescue Exception => e
          if is_recoverable(e)
            recover(tuple, e)
          else
            standard_error_response(@tuple[0], @tuple[2], e, @tuple)
          end
        ensure
          Thread.current[IS_DOING_SOMETHING_USEFUL] = false
        end
      end
    end

    # Extends original_with_tuple with thread_per_request model, which spawns a new thread for each request
    def with_tuple(tuple, pulse = @pulse, &block)
      return original_with_tuple(tuple, pulse, &block)
    end


    # Creates a tuple from context and task and yields it to the given block. Optional timeout
    #
    # Example:
    #
    #    with_standard_tuple("some_context", "some_task") do |tuple|
    #      # do something
    #    end
    #
    #
    def with_standard_tuple(context, task, pulse = @pulse, &block)
      with_tuple([context, "request", task], pulse, &block)
    end

    # Writes a standard error response tuple to the tuplespace, based on context, task, exception, tuple, and application id
    def standard_error_response(context, task, e, tuple, app_id, timeout=nil)
      log_exception(e)
      rinda_client.write([context, "response", task, @error_topic, e.to_s, tuple, app_id], timeout)
    end

    # Writes a monitor subscribe tuple for this rindlet
    def subscribe_to_monitor
      rinda_client.write(["monitor", "subscribe", name], 120)
    end

    # Writes a monitor unsubscribe tuple for this rindlet
    def unsubscribe_to_monitor
      rinda_client.write(["monitor", "unsubscribe", name], 2)
    end

    # Checks the tuplespace for a ping message for this rindlet
    def check_for_ping
      @pinging = true
      with_tuple([name, "ping"], 0) do |tuple|
        rinda_client.write(["monitor", "pong", name], @pong_timeout)
      end
      @pinging = false
    end

    # Logs exception and retries writing the tuple
    def recover(tuple, exception)
      $logger.info "#{name} recovering tuple from exception: #{exception}"
      rinda_client.delayed_write(@retry_delay, tuple)
    end

    private ###############################################

    # Takes a tuple and returns nil if a timeout occurs
    def take_with_timeout(wildcard_tuple, timeout)
      catch_expiration { rinda_client.take(wildcard_tuple, timeout) }
    end

    def take_is_possible?(wildcard_tuple)
      !!catch_expiration { rinda_client.read(wildcard_tuple, 0) }
    end


    # this method is used to ensure that RindaClient timeout errors don't cause the rindlet to exit
    def catch_expiration
      yield if block_given?
    rescue RindaIsDownError => ex
      handle_rinda_down_error(ex)
      return nil
    rescue ThreadError => ex
      # unexpected problem, log it with a stacktrace
      log_exception(ex)
      return nil
    end

    def handle_rinda_down_error(ex)
      # log it every 60 seconds without a backtrace
      its_time = @last_rinda_down_message.nil? || Time.now > (@last_rinda_down_message + 60)
      if its_time
        @last_rinda_down_message = Time.now
        log_exception(ex, false)
      end

    end


    def enter_loop
      begin
        while @running
          check_for_ping
          @is_loaded_cycle = false
          run
          # @load_calculator.cycle(@is_loaded_cycle)
        end
      rescue Exception => ex
        log_exception(ex)
      end
    end

    # Runs the rindlet in a loop as long as the result of executing the block is true.
    # This implementation does not ping-pong with monitor, nor attempt to load/manage instances with a load_calculator
    def do_loop
      raise "do_loop must be given a block specifying a stop condition" unless block_given?
      begin
        run while yield
      rescue Exception => ex
        log_exception(ex)
      end
    end


    def is_recoverable(exception)
      return @recoverable_exceptions.include?(exception.class)
    end

    def log_exception(e, log_backtrace=true)
      $logger.error "Rindlet Error in #{self.class} #{Thread.current}: #{e}"
      $logger.error e.backtrace.join("\n") if log_backtrace
    end


  end
end
