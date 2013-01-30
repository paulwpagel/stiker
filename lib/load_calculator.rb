module Rinda
  
  class LoadCalculator
    
    attr_reader :cycles, :sample

    # Associates the LoadCalculator with a rindlet
    def initialize(rindlet)
      @rindlet = rindlet
      @cycles = 0
      @sample = []
    end
    
    # Computes a load factor from 0 to 100 that indicates roughly what percentage of cycles are loaded.
    def load_factor
      loaded_cycles = 0
      @sample.each do |cycle_loaded| 
        loaded_cycles += 1 if cycle_loaded
      end
      return loaded_cycles * 10
    end
    
    # Records a sample from the rindlet, indicating whether the last cycle executed was loaded or not.
    def cycle(loaded)
      @sample << loaded      
      @cycles += 1
      process_sample
    end
    
    # Records a sample from the rindlet, indicating whether the last cycle executed was loaded or not.
    def process_sample
      @sample.shift while @sample.length > 10
      spawn if @sample.length == 10 && load_factor >= 3
      die if @sample.length == 10 && load_factor <= 1
    end

    # Causes the <tt>Rindlet::RindletContext</tt> associated with the rindlet to spawn a new instance of itself
    def spawn
      $rindlet_context.invoke_new_instance
      @sample = []
    end
    
    # Causes the <tt>Rindlet::RindletContext</tt> associated with the rindlet to kill a process that is running the rindlet
    def die
      $rindlet_context.kill_last_instance
      @sample = []
    end
    
  end
  
end