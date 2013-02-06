require File.expand_path(File.dirname(__FILE__) + "/../rindlet")
require "fastercsv"

class StockSourceRindlet < Rinda::Rindlet
  CSV_FILE_PATH = File.expand_path(File.dirname(__FILE__) + "/../../data/")
  STOCKS = 
  {  
    "AAPL"  => 0,
    "AMZN"  => 0,
    "BAC"   => 0,
    "BRK-A" => 0,
    "CSCO"  => 0,
    "EBAY"  => 182,
    "GE"    => 0,
    "GOOG"  => 1666,
    "GS"    => 0,
    "HPQ"   => 0,
    "MSFT"  => 0,
    "NVR"   => 0,
    "XOM"   => 0  
  }

  def initialize(name)
    @name = name
    @row = 0
    
    sleep STOCKS[name]
    @source = []
    FasterCSV.foreach("#{CSV_FILE_PATH}/#{@name}.csv") do |line|
      @source << line[1]
    end
    
    rinda_client.write(["stock", name, @source.pop])
  end

  def run
    with_tuple(["stock", name]) do |tuple|
      old_price = tuple[2].to_f
      new_price = @source.pop
      $logger.info "Updating #{@name} from #{old_price} to #{new_price}"
      rinda_client.write(["stock", name, new_price])
      sleep 2
    end
  end

end
