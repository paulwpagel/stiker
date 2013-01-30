require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'rindlet_context'
require 'fileutils'
require "logging"


PROCESS_DIR = "garbage"

describe Rinda::RindletContext do

  before(:each) do
    FileUtils.rm_r(PROCESS_DIR, :force => true) if File.exists?(PROCESS_DIR)
    @context = Rinda::RindletContext.new("foo")
    $logger = MockLogger.new
  end
  
  after(:each) do
    FileUtils.rm_r(PROCESS_DIR, :force => true) if File.exists?(PROCESS_DIR)
  end
  
  it "should have some names" do
    @context.full_rindlet_name = "ModName::InnerMod::FooRindlet"
    
    @context.full_rindlet_name.should == "ModName::InnerMod::FooRindlet"
    @context.rindlet_name.should == "FooRindlet"
    @context.rindlet_file_name.should == "mod_name/inner_mod/foo_rindlet"
  end
  
  it "should have default instances and thresholds" do    
    @context.min_instances.should == 1
    @context.max_instances.should == 1
    @context.min_threshold.should == 20
    @context.max_threshold.should == 60
  end
  
  it "should accept options and the name of the rindlet" do
    options = {:foo_min_instances => 2, :foo_max_instances => 5, :foo_min_threshold => 10, :foo_max_threshold => 100}
    context = Rinda::RindletContext.new("foo", options)
    
    context.min_instances.should == 2
    context.max_instances.should == 5
    context.min_threshold.should == 10
    context.max_threshold.should == 100
  end
  
  it "accepts option for separate logger" do
    options = {:foo_separate_logger => true}
    
    context = Rinda::RindletContext.new("foo", options)
    
    context.separate_logger.should be_true
  end
  
  it "should have a name processes dir" do
    @context.system_name = "bar"
    @context.processes_dir = "/processes"
    
    @context.processes_dir.should == "/processes"
    @context.pid_dir.should == "/processes/pids"
    @context.data_file.should == "/processes/data/foo.data"
    @context.lock_file.should == "/processes/lock/foo.lock"
  end
  
  it "uses system name for logger name, which is the default" do
    $logger = nil
    @context.system_name = "foo"
    
    Logging.should_receive(:create_unique_machine_logger).with("foo_rindlet_daemon", CONFIG[:log_directory])
    
    @context.make_logger
  end
  
  it "should create a logger" do
    Dir.mkdir(PROCESS_DIR)
    Dir.mkdir(File.join(PROCESS_DIR, "logs"))
  
    @context.name = "foo"
    @context.processes_dir = PROCESS_DIR
    CONFIG[:log_directory] = PROCESS_DIR
    $logger = nil

    @context.make_logger
    
    $logger.class.should == Log4r::Logger
  end
  

  
  it "uses rindlet_name for logger name if separate logger" do
    $logger = nil
    @context.separate_logger = true
    @context.rindlet_name = "bar"
    
    Logging.should_receive(:create_unique_machine_logger).with("bar_daemon", CONFIG[:log_directory])
    
    @context.make_logger
  end
  
  
  it "should have a config file" do
    @context.config_file = "blah"
    
    @context.config_file.should == "blah"
  end
  
  it "should refresh from data file" do
    Dir.mkdir(PROCESS_DIR)
    Dir.mkdir(File.join(PROCESS_DIR, "data"))
  
    @context.processes_dir = PROCESS_DIR
    
    data = {:instances => 5, :time => Time.now.to_i }
    File.open(@context.data_file, 'w') { |file| file.write YAML::dump(data) }
    
    @context.refresh
    
    @context.inactive_time.should < 5
    @context.instances.should == 5
    @context.next_number.should == 6
  end
  
  it "should not error if yaml doesn't load" do
    File.stub!(:exists?).and_return(true)
    IO.stub!(:read)
    YAML.should_receive(:load).and_return(false)

    @context.refresh
  end
  
  it "should increment number on next number" do
    @context.next_number.should == 1
    @context.next_number.should == 2
    @context.next_number.should == 3
    @context.next_number.should == 4
  end
  
  it "should save" do
    prep
    
    @context.next_number
    
    @context.save
    
    data_file_contents = IO.read(@context.data_file)
    hash = YAML::load(data_file_contents)
    hash[:instances].should == 1
    hash[:time].should_not == nil
    (Time.now.to_i - hash[:time]).should < 5
    (Time.now.to_i - @context.last_activity).should < 1
  end

  it "should generate require attempts" do
    @context.require_attempts("blah.rb").should == ["blah.rb", "/blah.rb"]
    @context.require_attempts("foo/blah.rb").should == ["foo/blah.rb", "/foo/blah.rb", "blah.rb", "/blah.rb"]
    @context.require_attempts("bar/foo/blah.rb").should == ["bar/foo/blah.rb", "/bar/foo/blah.rb", "foo/blah.rb", "/foo/blah.rb", "blah.rb", "/blah.rb"]
  end
  
  it "should generate require attempts with rindlet dir" do
    @context.rindlet_dir = "grandparent/parent"
    @context.require_attempts("blah.rb").should == ["blah.rb", "grandparent/parent/blah.rb"]
    @context.require_attempts("foo/blah.rb").should == ["foo/blah.rb", "grandparent/parent/foo/blah.rb", "blah.rb", "grandparent/parent/blah.rb"]
    @context.require_attempts("bar/foo/blah.rb").should == ["bar/foo/blah.rb", "grandparent/parent/bar/foo/blah.rb", "foo/blah.rb", "grandparent/parent/foo/blah.rb", "blah.rb", "grandparent/parent/blah.rb"]  
  end
  
  it "should know pid file names" do
    prep
    
    @context.pid_file(4).should == "#{PROCESS_DIR}/pids/FooRindlet_4.pid"
  end
  
  it "should kill the last instance" do
    prep
    File.open(@context.data_file, 'w') { |file| file.write(YAML::dump({:instances => 4, :time => Time.now.to_i - 31}))}
    File.open(@context.pid_file(4), 'w') { |file| file.write "123" }

    Process.should_receive(:kill).with("TERM", 123)
    
    @context.kill_last_instance
  end
  
  it "should be locked after first save" do
    prep
    @context.save
    
    @context.locked?.should == true
  end
  
  def prep
    Dir.mkdir(PROCESS_DIR)
    %w(pids data lock).each { |d| Dir.mkdir(File.join(PROCESS_DIR, d)) }
    @context.processes_dir = PROCESS_DIR
    @context.full_rindlet_name = "ModName::InnerMod::FooRindlet"
  end
  
  it "should not be locked if the inactive time is longer than 30 seconds " do
    prep
    File.open(@context.data_file, 'w') { |file| file.write(YAML::dump({:time => Time.now.to_i - 31}))}
    @context.last_activity = 0
    
    @context.locked?.should be(false)
  end
  
  it "should spawn a new instance if the minimum instances have been satisfied" do
    prep
    @context.min_instances = 2
    Daemons.should_receive(:run_proc)
    File.open(@context.pid_file(1), 'w') { |file| file.write("123") }
    File.open(@context.pid_file(2), 'w') { |file| file.write("321") }
    File.open(@context.data_file, 'w') { |file| file.write(YAML::dump({:instances => 2}))}
    
    @context.process
  end
  
  it "should spawn the min processes" do
    prep
    @context.min_instances = 3
    Daemons.should_receive(:run_proc).exactly(3).times
    
    @context.process
  end
  
  it "should not reuse an invalid data file" do
    prep
    @context.min_instances = 2
    Daemons.should_receive(:run_proc).twice
    File.open(@context.data_file, 'w') { |file| file.write(YAML::dump({:instances => 2}))}
    
    @context.process
  end
  
  it "should not kill if you are at miniumun " do
    prep
    @context.min_instances = 2
    Process.should_not_receive(:kill)
    File.open(@context.pid_file(1), 'w') { |file| file.write("123") }
    File.open(@context.pid_file(2), 'w') { |file| file.write("321") }
    File.open(@context.data_file, 'w') { |file| file.write(YAML::dump({:instances => 2}))}
    
    @context.kill_last_instance
  end
  
  it "should not invoke a new instance if at max" do
    prep
    @context.max_instances = 2
    File.open(@context.pid_file(1), 'w') { |file| file.write("123") }
    File.open(@context.pid_file(2), 'w') { |file| file.write("321") }
    File.open(@context.data_file, 'w') { |file| file.write(YAML::dump({:instances => 2}))}  
    Kernel.should_not_receive(:system)
    
    @context.invoke_new_instance
  end
  
  it "should not invoke multiple instances at the same time" do
    prep
    File.open(@context.data_file, 'w') { |file| file.write(YAML::dump({:instances => 1, :time => Time.now.to_i - 31}))}
    Kernel.should_receive(:system).once
    
    5.times do
      Thread.new do
        begin
          context = Rinda::RindletContext.new("foo")
          context.processes_dir = PROCESS_DIR
          context.full_rindlet_name = "ModName::InnerMod::FooRindlet"
          context.max_instances = 5
          context.startup_script = "echo"
          context.args = ["'blah'"]
          context.invoke_new_instance 
        rescue Exception => e
          puts e
        end
      end
    end
    sleep(0.5)
  end
  
  it "should not kill multiple instances at the same time" do
    prep
    File.open(@context.data_file, 'w') { |file| file.write(YAML::dump({:instances => 6, :time => Time.now.to_i - 31}))}
    6.times { |i| File.open(@context.pid_file(i + 1), 'w') {|file| file.write "#{i}"} }
    Process.should_receive(:kill).once
    
    5.times do
      Thread.new do
        begin
          context = Rinda::RindletContext.new("foo")
          context.processes_dir = PROCESS_DIR
          context.full_rindlet_name = "ModName::InnerMod::FooRindlet"
          context.min_instances = 1
          context.startup_script = "echo"
          context.args = ["'blah'"]
          context.kill_last_instance 
        rescue Exception => e
          puts e
        end
      end
    end
    sleep(0.5)
  end

end
