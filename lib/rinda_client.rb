require 'rinda/rinda'
require 'tuplespace_proxy_management'

module Rinda
  class RindaIsDownError < Exception ; end

  # Provides a high-level reusable client to read, write, take and notify on a tuplespace.
  class RindaClient
    include TupleSpaceProxyManagement

    # Writes a tuple instance that responds to <tt>to_ary</tt>
    # EWM - Added this method to encapsulate the tuple behavior.  Didn't want to rename the "write" method (yet)
    def write_tuple(tuple_instance)
      write(tuple_instance.to_ary, tuple_instance.timeout)
    end

    # Writes a plain old tuple (i.e. an Array)
    def write(tuple, timeout = nil)
      with_tuplespace(timeout) do |tuplespace| 
        tuplespace.write(standardize(tuple), timeout) 
      end
    end

    # Writes a tuple with after the specified delay
    def delayed_write(delay, tuple)
      tuple = standardize(tuple)
      with_tuplespace(nil) { |tuplespace| tuplespace.write(["delay", tuple], delay) }
    end

    # Takes a tuple matching the given tuple
    def take(tuple, timeout = nil)
      with_tuplespace(timeout) do |tuplespace|
        return tuplespace.take(standardize(tuple), timeout)
      end
    end

    # Reads a tuple matching the given tuple
    def read(tuple, timeout = nil)
      with_tuplespace(timeout) do |tuplespace|
        return tuplespace.read(standardize(tuple), timeout)
      end
    end

    # Sends a notify to the tuplespeace for the event with specified timeout if given
    def notify(event, tuple, timeout = nil)
      with_tuplespace(timeout) { |tuplespace| return tuplespace.notify(event, standardize(tuple), timeout)}
    end

    private ###############################################

    def with_tuplespace(timeout)
      expiration = timeout ? Time.now + timeout : nil
      begin
        tuplespace = self.class.tuplespace
        yield tuplespace if block_given?
      rescue DRb::DRbServerNotFound
        self.class.close
        retry
      rescue RequestExpiredError
        return nil
      rescue DRb::DRbConnError
        sleep(0.1)
        raise RindaIsDownError.new("Connection to Rinda server (at #{self.class.url}) could not be established within desired duration (#{timeout} secs).") if expired?(expiration)
        retry
      end
    end

    def expired?(expiration)
      return false if expiration.nil?
      return Time.now > expiration
    end

    def standardize(tuple)
      standard_tuple = Array.new(10)
      tuple.each_with_index { |value, index| standard_tuple[index] = value }
      return standard_tuple 
    end

  end
end
