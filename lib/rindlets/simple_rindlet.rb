require File.expand_path(File.dirname(__FILE__) + "/../rindlet")

module Rinda
  class SimpleRindlet < Rindlet
  
    def initialize
      super(1)
      @rinda_client = RindaClient.new
      @rinda_client.write(["simple", "0"])
    end

    def run
      with_tuple(["simple"]) do 
        sleep 1
        $logger.info @tuple[1]
        @rinda_client.write(["simple", (@tuple[1].to_i + 1).to_s], 10)
      end
    end
  
  end 

  class SimpleLogger
  
    def info(message)
      puts message
    end
  
    def error(message)
      puts message
    end
  
  end
end

CONFIG = {:rinda_port => 6683, :rinda_host => "localhost"} unless defined?(CONFIG)
$logger = Rinda::SimpleLogger.new
Rinda::SimpleRindlet.new.start