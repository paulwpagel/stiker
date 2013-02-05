require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require "mock_rinda_client"
require "rindlet"


class TestRindlet < Rinda::Rindlet
  attr_accessor :method_calls, :tuple, :matched_tuple, :match

  def initialize()
    @method_calls = []
    @tuple = []
    @match = nil
  end
  
  def run
    with_tuple(@match) do |tuple|
      @matched_tuple = tuple
      nil
    end
  end
  
  def prepare
    @method_calls << :prepare
  end

  def shutdown
    @method_calls << :finish_up
  end
  
end


describe Rinda::Rindlet do
  let!(:rindlet) { TestRindlet.new }
  let!(:rinda_client) { MockRindaClient.new }

  before do 
    rindlet.rinda_client = rinda_client
  end
  
  it "names the rindlet the class name" do
    rindlet.name.should == "TestRindlet"
  end
  
  it "calls prepare" do
    rindlet.startup
    rindlet.method_calls.should include(:prepare)
  end
  
  it "calls finish up" do
    rindlet.shutdown
    rindlet.method_calls.should include(:finish_up)
  end
  
  it "takes with tuple" do
    tuple = ['test', 1, 2, 3]
    rinda_client.takes << ['test', tuple]

    rindlet.tuple = tuple
    rindlet.match = 'test'

    rindlet.run
    rindlet.matched_tuple.should == tuple
  end
    
end