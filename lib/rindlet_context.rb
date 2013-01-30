require 'daemons'
require 'yaml'

module Rinda

  # Manages rindlet instances (i.e. processes), creating and destroying them and keeping track of their process ids
  # Also tracks the time of last activity and number of instances for a +RindletContext+ in a data file that is
  # controlled with a loose semaphore called a <tt>lock_file</tt>.
  class RindletContext

    # full rindlet name including enclosing modules
    attr_reader :full_rindlet_name
    # the rindlet class name without enclosing modules
    attr_accessor :rindlet_name
    # unique path based on mangling of <tt>full_rindlet_name</tt>
    attr_reader :rindlet_file_name

    # filesystem path for process dir
    attr_reader :processes_dir
    # filesystem path for pids dir
    attr_reader :pid_dir
    # filesystem path for log file
    attr_reader :log_file
    # filesystem path for data file
    attr_reader :data_file
    # filesystem path for lock file
    attr_reader :lock_file

    # min number of instances of this type of rindlet
    attr_accessor :min_instances
    # max number of instances of this type of rindlet
    attr_accessor :max_instances

    # used to determine whether to spawn new RindletContext instances
    attr_reader :min_threshold
    # used to determine whether to spawn new RindletContext instances
    attr_reader :max_threshold
    # the number of rindlet instances controlled by this +RindletContext+
    attr_reader :instances

    # points to the environment config file for the top level project, which loads the config corresponding to RAILS_ENV
    attr_accessor :config_file

    # a parameter 
    attr_accessor :timeout
    # the full rindlet name
    attr_accessor :name
    # the last time the data file was updated by this +RindaContext+
    attr_accessor :last_activity
    # the script that created this +RindaContext+
    attr_accessor :startup_script
    # the arguments passed to the script that created this +RindaContext+
    attr_accessor :args
    # path to where the rindlet code is
    attr_accessor :rindlet_dir
    # the system to which the rindlet belongs (used to name the logger)
    attr_accessor :system_name
    # allows a separate logger to be created, will use the rindlet_name instead of system_name
    attr_accessor :separate_logger
    
    def initialize(name, options = {})
      @name = name
      @min_instances = options["#{name}_min_instances".to_sym] || 1
      @max_instances = options["#{name}_max_instances".to_sym] || 1
      @min_threshold = options["#{name}_min_threshold".to_sym] || 20
      @max_threshold = options["#{name}_max_threshold".to_sym] || 60
      @separate_logger = options["#{name}_separate_logger".to_sym] || false
      
      @instances  = 0
      @last_activity = Time.now.to_i
      @has_lock = false
    end

    # Sets rindlet name attributes based on the given +Rindlet+ name
    def full_rindlet_name=(name)
      @full_rindlet_name = name
      @rindlet_name = name.split("::")[-1]
      @rindlet_file_name = calc_file_name
    end
    
    # Sets the directory where data, lock, and pid files for the process live
    def processes_dir=(dir)
      @processes_dir = dir
      @data_file = File.join(@processes_dir, "data", "#{name}.data")
      @lock_file = File.join(@processes_dir, "lock", "#{name}.lock")
      @pid_dir = File.join(@processes_dir, "pids")
    end

    # Instantiates a global logger
    def make_logger
      require "logging"
      $logger = Logging.create_unique_machine_logger(log_file_name_template, CONFIG[:log_directory]) if $logger.nil?
    end
    
    def log_file_name_template
      return @separate_logger ? "#{rindlet_name}_daemon" : "#{system_name}_rindlet_daemon"
    end

    # Mangles the rindlet name into a filename
    def calc_file_name
      name = @full_rindlet_name.gsub(/[A-Z]/) { |match| "_#{match.downcase}" }
      name = name.gsub("::", "/")
      name = name.gsub("/_", "/")
      return name[1..-1] 
    end

    # Starts up a new rindlet with the given instance number
    def start_up(number)
      $logger = nil
      begin
        require config_file
        make_logger
        require_rindlet
          
        rindlet_class = eval(@full_rindlet_name)
        rindlet = rindlet_class.new(number)
        
        Signal.trap("TERM") { rindlet.stop }
        rindlet.start
      rescue Exception => e
        puts e
        puts e.backtrace
        $logger.error "Error in #{name} Rindlet #{@rindlet_name}: #{e}"
        $logger.error "#{e.backtrace.join("\n")}"
      end
    end


    # tries to find the rindlet code to +require+ it
    def require_rindlet
      require_attempts(rindlet_file_name).each do |attempt|
        begin
          require attempt
          return
        rescue LoadError => e
        end
      end
      raise "Could not require rindlet file: #{rindlet_file_name}"
    end
    
    # produces a list of path to try to +require+
    def require_attempts(file_name)
      attempts = []
      file_name = file_name.split("/")
      full_path = nil
      prefix = rindlet_dir ? rindlet_dir : nil
      file_name.reverse.each do |path|
        full_path = "#{path}/#{full_path}" if full_path
        full_path = path unless full_path
        
        attempts << "#{prefix}/#{full_path}"
        attempts << full_path
        
      end
      return attempts.reverse
    end

    # Returns the path to this rindlets pid file
    def pid_file(number)
      return File.join(pid_dir, "#{@rindlet_name}_#{number}.pid")
    end

    # Creates a new instance of the rindlet (using <tt>Daemons.run_proc</tt>)
    def fork_instance
      refresh
      number = next_number
      $logger.info "Context(#{name}): forking new instance ##{number}"
      Daemons.run_proc("#{@rindlet_name}_#{number}", :log_output => true, :dir_mode => :normal, :dir => pid_dir, :timeout => timeout) { start_up(number) }
      save
    end

    # Starts up a new rindlet instance if this context is not locked (by calling the script that created this
    # <tt>RindletContext</tt> instance). This will cause the creation of a similar +RindletContext+ in a new process
    def invoke_new_instance
      should_invoke = false
      with_lock do
        refresh
        if @instances >= @max_instances
          # already at maximum instances
        elsif locked?
          # context is locked.  No instance will be spawned
        else
          save
          should_invoke = true
        end
      end
      
      Kernel.system "#{@startup_script} #{@args.join(' ')}" if should_invoke
    end

    # Starts up a new rindlet instance if this context is not locked (by calling the script that created this <tt>RindletContext</tt> instance)
    def process
      check_data_file
      make_logger     
      if @args && @args[0].downcase == "stop"
        kill_all_instances
      else
        spawn
      end
    end

    # Creates one or more rindlet instances until the number of instances equals <tt>min_instances</tt>
    def spawn     
      fork_instance
      spawn if @instances < @min_instances 
    end
    
    # Kills all rindlet instances in this +RindletContext+
    def kill_all_instances
      $logger.info "Context(#{name}): killing all instances" if $logger
      @instances.times do |i|
        kill_instance(i + 1)
      end
    end
    
    # Kills the last rindlet instances in this +RindletContext+ if there are more than <tt>min_instances</tt> running
    def kill_last_instance
      with_lock do
        refresh
        if @instances <= @min_instances
          # already at minimum instances
        elsif locked?
          # context is locked.  No instance will be killed.
        else
          save
          kill_instance(@instances)
        end
      end
    end
    
    # Kills the nth rindlet instances in this +RindletContext+
    def kill_instance(number)
      begin
        pid = IO.read(pid_file(number))
        $logger.info "Context(#{name}): sending TERM to instance ##{number}, process: #{pid}"      
        Process.kill("TERM", pid.to_i)
      rescue Exception => e
        $logger.info "Context(#{name}): failed to kill instance ##{number}, process: #{pid}" 
      end
      @instances -= 1
      save
    end
    
    # Returns the next rindlet instance number (i.e. +instances+ + 1)
    def next_number
      @instances += 1
      return @instances
    end

    # Returns the number of seconds since the last activity
    def inactive_time
      return Time.now.to_i - @last_activity.to_i
    end
    
    # Updates the last_activity time from the data file if <tt>inactive_time</tt> is greater than 30 seconds. Returns
    # true if the <tt>inactive_time</tt> is less than 30 seconds
    def locked?
      refresh if inactive_time >= 30
      return inactive_time < 30
    end
    
    # Updates the number of instances and last_activity time from the data file
    def refresh
      return if !File.exists?(data_file)
      contents = IO.read(data_file)
      options = YAML::load(contents)
      if options
        @instances = options[:instances]
        @last_activity = options[:time] 
      end
    end

    # Updates the data file with instances and time of last activity data
    def save
      # TODO DRY up to one-liner: with_lock { save_without_lock }
      if @has_lock
        save_without_lock
      else
        with_lock { save_without_lock }
      end
    end

    # Updates the data file with instances and time of last activity data
    def save_without_lock
      options = {}
      options[:instances] = instances
      options[:time] = @last_activity = Time.now.to_i
      content = YAML.dump(options)
      File.open(data_file, "w") { |file| file.write(content) }
    end

    # Run the given block only after the semaphore has been acquired (see <tt>acquire_lock</tt>
    def with_lock
      acquire_lock
      begin
        yield
      rescue Exception => e
        raise e
      end
      
      #TODO - JTS - This should be in an ensure, if an exception is raised, the lock file never gets cleaned up.
      remove_lock
    end
    
    # Grabs the semaphore by waiting for the lock file to disappear and then creating the lock file
    def acquire_lock
      return if @has_lock
      sleeps = 0
      while(File.exists?(lock_file))
        raise "Could not acquire lock: #{lock_file}" if sleeps >= 50
        sleep(0.1)
        sleeps += 1
      end
      File.open(lock_file, 'w') { |file| file.write "locked" }  
      @has_lock = true
    end

    # Releases the semaphore
    def remove_lock
      begin
        File.delete(lock_file) if File.exists?(lock_file)
      rescue
        #File already deleted
      end
      @has_lock = false
    end


    # Updates the number of instances and last_activity time from the data file if the pid file exists. Otherwise it
    # deletes the data file.
    def check_data_file
      if File.exists?(pid_file(1))
        refresh 
      else
        File.delete(data_file) if File.exists?(data_file)
      end
    end
    
  end
  
end
