require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'logging'

describe "Logging" do
  
  before(:all) do
    Log4r.const_set("DEBUG", 1)
  end
  
  after(:all) do
    Log4r.module_eval { remove_const("DEBUG") }
  end
  
  before(:each) do
    Socket.stub!(:gethostname).and_return("amd-212")
  end
  
  describe "logger creation" do

    before(:each) do
      @name = "app_name"
      @filename = "filename"
      @dir = "/tmp/some_dir"
      @logger = mock("Log4r::Logger", :level= => nil, :add => nil)
      @formatter = mock("Log4r::PatternFormatter")
      @outputter = mock("Log4r::FileOutputter", :formatter= => nil)
      
      Log4r::Logger.stub!(:new).and_return(@logger)
      Log4r::PatternFormatter.stub!(:new).and_return(@formatter)
      Log4r::DateFileOutputter.stub!(:new).and_return(@outputter)
      
      Logging.stub!(:unique_log_file_name).and_return("the_unique_file")
    end
    
    describe "logger" do
      
      it "creates a Log4r logger" do
        Log4r::Logger.should_receive(:new).with("app_name").and_return(@logger)

        Logging.create_logger(@name, @filename, @dir)
      end

      it "sets log level to debug" do
        @logger.should_receive(:level=).with(Log4r::DEBUG)

        Logging.create_logger(@name, @filename, @dir)
      end

      it "creates the correct formatter" do
        pattern = "[%l][#{Socket.gethostname}][%c][#{Process.pid}][%d] :: %m"
        Log4r::PatternFormatter.should_receive(:new).with(:pattern => pattern).and_return(@formatter)

        Logging.create_logger(@name, @filename, @dir)
      end

      it "creates the correct outputter" do
        log_dir = "/tmp/directory"
        options = {:trunc => false, :filename => @filename, :date_pattern => "%Y-%m-%d", :dirname => log_dir}
        Log4r::DateFileOutputter.should_receive(:new).with(@name, options).and_return(@outputter)

        Logging.create_logger(@name, @filename, log_dir)
      end

      it "sets the formatter on the outputter" do
        @outputter.should_receive(:formatter=).with(@formatter)

        Logging.create_logger(@name, @filename, @dir)
      end

      it "adds the name to the logger" do
        @logger.should_receive(:add).with(@name)

        Logging.create_logger(@name, @filename, @dir)
      end

    end
    
    describe "shared logger" do
      
      it "uses shared log file name" do
        Logging.should_receive(:create_logger).with(@name, "#{@name}.log", "/some_dir/logs")

        Logging.create_shared_logger(@name, "/some_dir")
      end
      
    end
    
    describe "unique machine logger" do

      it "uses unique log file name with machine hostname" do
        Logging.should_receive(:create_logger).with(@name, "#{@name}_#{Socket.gethostname}.log", "/some_dir/logs")
        
        Logging.create_unique_machine_logger(@name, "/some_dir")
      end

    end
    
    describe "unique logger" do

      it "uses unique log file name" do
        Logging.should_receive(:create_logger).with(@name, "#{@name}_#{Socket.gethostname}_#{Process.pid}.log", "/some_dir/logs")
        
        Logging.create_unique_logger(@name, "/some_dir")
      end

    end
    
  end
  
end

describe Log4r::Logger do
  
  before(:each) do
    @logger = Log4r::Logger.new('test_logger')
    @outputter = Log4r::IOOutputter.new('test_logger', {})
    @logger.add('test_logger')
  end
  
  it "should send error message without any identifiers" do
    @outputter.should_receive(:write).with("ERROR test_logger:  Oh my god, you killed Kenny.\n")
    
    @logger.pb_error("Oh my god, you killed Kenny.")
  end

  it "should send error message for application_id" do
    @outputter.should_receive(:write).with("ERROR test_logger: [application_id=1] Oh my god, you killed Kenny.\n")
    
    @logger.pb_error("Oh my god, you killed Kenny.", :application_id => 1)
  end
  
  it "should send error message for tracking_id" do
    @outputter.should_receive(:write).with("ERROR test_logger: [tracking_id=BASTARD] You bastards!\n")
    
    @logger.pb_error("You bastards!", :tracking_id => "BASTARD")
  end
  
  it "should send error message for esign_key" do
    @outputter.should_receive(:write).with("ERROR test_logger: [esign_key=ABCDEFG] Paul Broke the Yo-Yo!\n")

    @logger.pb_error("Paul Broke the Yo-Yo!", :esign_key => "ABCDEFG")
  end
  
  it "should send info message for application_id" do
    @outputter.should_receive(:write).with(" INFO test_logger: [application_id=1] Oh my god, you may have injured Kenny.\n")
    
    @logger.pb_info("Oh my god, you may have injured Kenny.", :application_id => 1)
  end
  
  it "should send info message for tracking_id" do
    @outputter.should_receive(:write).with(" INFO test_logger: [tracking_id=BadPerson] You sorta bad people.\n")
    
    @logger.pb_info("You sorta bad people.", :tracking_id => "BadPerson")
  end
  
  it "should send info message for esign_key" do
    @outputter.should_receive(:write).with(" INFO test_logger: [esign_key=ABCDEFG] Paul dropped the Yo-Yo!\n")

    @logger.pb_info("Paul dropped the Yo-Yo!", :esign_key => "ABCDEFG")
  end
  
  it "should send info message for application_id" do
    @outputter.should_receive(:write).with("FATAL test_logger: [application_id=1] Oh my god, Kenny is a blood stain on the carpet.\n")
    
    @logger.pb_fatal("Oh my god, Kenny is a blood stain on the carpet.", :application_id => 1)
  end
  
  it "should send info message for tracking_id" do
    @outputter.should_receive(:write).with("FATAL test_logger: [tracking_id=@$%#] You @$%#s!\n")
    
    @logger.pb_fatal("You @$%#s!", :tracking_id => "@$%#")
  end
  
  it "should send info message for esign_key" do
    @outputter.should_receive(:write).with("FATAL test_logger: [esign_key=ABCDEFG] Paul decimated the Yo-Yo, and killed Doug too.\n")

    @logger.pb_fatal("Paul decimated the Yo-Yo, and killed Doug too.", :esign_key => "ABCDEFG")
  end  
  
end
