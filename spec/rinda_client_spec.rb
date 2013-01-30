require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require "rinda_client"

class MemoryTuplespace
  attr_reader :writes
  
  def initialize
    @writes = []
  end
  
  def write(value, timeout = 0)
    @writes << value
  end
  
  def clear_writes
    @writes = []
  end
  
end

class SimpleTuple
  def to_ary
    ["one", "two", "three"]
  end
  
  def timeout
    12345
  end
end

describe Rinda::RindaClient do
  
  before(:all) do
    @tuplespace = MemoryTuplespace.new
    Rinda::RindaClient.set_tuplespace(@tuplespace)
  end
  
  before(:each) do
    @tuplespace.clear_writes
    @client = Rinda::RindaClient.new
  end
  
  it "should write a tuple" do
    @client.write ["one", "two"]
    
    @tuplespace.writes.should include(["one", "two", nil, nil, nil, nil, nil, nil, nil, nil])
  end

  it "should accept an instance of a tuple class" do
    tuple = SimpleTuple.new
    @client.write_tuple tuple
    
    @tuplespace.writes.should include(["one", "two", "three", nil, nil, nil, nil, nil, nil, nil])
  end
  
  it "should get the timeout from the tuple" do
    tuple = SimpleTuple.new
    @tuplespace.should_receive(:write).with(anything(), 12345)

    @client.write_tuple tuple
  end

  it "take catches request expired error" do
    @tuplespace.should_receive(:take).and_raise(Rinda::RequestExpiredError)
    @client.take([nil]).should be_nil
  end

  it "read catches request expired error" do
    @tuplespace.should_receive(:read).and_raise(Rinda::RequestExpiredError)
    @client.read([nil]).should be_nil
  end

  it "write catches request expired error" do
    @tuplespace.should_receive(:write).and_raise(Rinda::RequestExpiredError)
    @client.write([nil]).should be_nil
  end

end