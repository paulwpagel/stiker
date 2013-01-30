require 'rinda/rinda'
require 'monitor'
require 'uri'

module Rinda

  # The responsibility for managing the connection to the tuplespace is encapsulated here.
  module TupleSpaceProxyManagement

    def self.included(c)
      c.extend(ClassMethods)
    end

    module ClassMethods
      attr_accessor :url

      @@lock = Monitor.new

      # Set the rinda url to the value of new_url (which must be a String)
      def url=(new_url)
        URI.parse(new_url) # raise exception if invalid URL

        # changing the url after tuplespace exists closes the existing tuplespace (it is re-opened lazily)
        close if @tuplespace && (new_url != @url)

        @url = new_url
      end

      # all instances of +RindaClient+ use the same tuplespace
      def tuplespace
        @@lock.synchronize { @tuplespace ||= new_tuplespace }
      end

      # creates a new tuplespace using TupleSpaceProxy
      def new_tuplespace
        @@lock.synchronize {
          @server = DRb.start_service
          @tuplespace = Rinda::TupleSpaceProxy.new(DRbObject.new(nil, service_url))
        }
      end

      # Allows an instance to be parameterized with a tuplespace
      def set_tuplespace(tuplespace)
        @@lock.synchronize { @tuplespace = tuplespace }
      end

      # Shuts down the tuplespace for all instances
      def close
        @@lock.synchronize {
          @tuplespace = nil
          @server.stop_service
        }
      end

      def service_url
        url || "druby://#{CONFIG[:rinda_host]}:#{CONFIG[:rinda_port]}"
      end

    end

  end
end


