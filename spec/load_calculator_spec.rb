require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require "rindlet"
require 'load_calculator'
require 'rindlet_context'

describe Rinda::LoadCalculator do

  before(:each) do
    $rindlet_context = Rinda::RindletContext.new("foo")
    @rindlet = Rinda::Rindlet.new(1, 0)
    @calculator = Rinda::LoadCalculator.new(@rindlet)
  end
  
  it "should not spawn until a complete sample is gathered" do
    @calculator.should_not_receive(:spawn)
    
    9.times { @calculator.cycle(true) }
  end
  
  it "should not die until a complete sample is gathered" do
    @calculator.should_not_receive(:die)
    
    9.times { @calculator.cycle(false) }
  end
  
  it "should spawn when a complete sample is gatheres that exceeds threshold" do
    @calculator.should_receive(:spawn)
    
    6.times { @calculator.cycle(true) }
    4.times { @calculator.cycle(false) }
  end
  
  it "should spawn when a complete sample is gatheres that exceeds threshold" do
    @calculator.should_receive(:die)
    
    2.times { @calculator.cycle(true) }
    8.times { @calculator.cycle(false) }
  end
  
  it "should clear the sample after spawning" do
    $rindlet_context.should_receive(:invoke_new_instance)
    
    10.times { @calculator.cycle(true) }
    
    @calculator.sample.length.should == 0
  end
  
  it "should clear the sample after dieing" do
    $rindlet_context.should_receive(:kill_last_instance)
    
    10.times { @calculator.cycle(false) }
    
    @calculator.sample.length.should == 0
  end

end