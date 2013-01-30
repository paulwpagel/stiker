class MockRindaClient

  attr_accessor :takes, :writes, :delayed_writes, :timeouts

  def initialize
    clear
  end

  def read(tuple, timeout = nil)
    p = @takes.detect {|pair| pair[0] == tuple}
    return p && p[1]
  end

  def take(tuple, timeout = nil)
    @takes.each_with_index do |pair, index|
      if pair[0] == tuple
        @takes.delete_at(index)
        return pair[1]
      end
    end
    return nil
  end

  def notify(event, tuple, timeout = nil)
    @takes.select {|pair| pair[0] == tuple }.map {|p| ['write', p[0]]} 
  end

  def write(tuple, timeout = nil)
    @writes << tuple
    @timeouts << timeout
  end

  def write_tuple(tuple_instance)
    write(tuple_instance.to_ary, tuple_instance.timeout)
  end

  def delayed_write(delay, tuple)
    @delayed_writes << [delay, tuple]
  end

  def self.close
  end

  def clear
    @takes = []
    @writes = []
    @timeouts = []
    @delayed_writes = []
  end

end
