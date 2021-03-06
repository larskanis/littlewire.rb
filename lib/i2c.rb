class LittleWire::I2C
  def initialize wire
    @wire = wire
    @wire.control_transfer(function: :i2c_init)
  end
  
  # start an i2c message
  #
  # Arguments:
  #   address: (Integer) 7 bit numeric address
  #   direction: (Symbol) :in or :out
  def start address_7bit, direction
    direction = 1 if direction == :out || direction == :output || direction == :write
    direction = 0 if direction != 1
    config = (address_7bit.to_i << 1) | direction
    @wire.control_transfer(function: :i2c_begin, wValue: config)
    @wire.control_transfer(function: :read_buffer, dataIn: 8).bytes.first != 0
  end
  
  # read bytes from i2c device, optionally ending with a stop when finished
  def read length, endWithStop = false
    @wire.control_transfer(function: :i2c_read, wValue: (length.to_i & 0xFF) << 8 | (endWithStop ? 1 : 0))
    @wire.control_transfer(function: :read_buffer, dataIn: 8)[0...length.to_i]
  end
  
  # write data to i2c device, optionally sending a stop when finished
  def write send_buffer, end_with_stop = false
    send_buffer = send_buffer.pack('c*') if send_buffer.is_a? Array
    raise "Send buffer is too long" if send_buffer.length > 7
    
    # TODO: Send multiple requests to handle send buffers longer than 7 bytes
    @wire.control_transfer(
      wRequest: 0xE0 | send_buffer.length | (end_with_stop << 3),
      wValue: (send_buffer.bytes[1] << 8) + send_buffer.bytes[0],
      wIndex: (send_buffer.bytes[3] << 8) + send_buffer.bytes[2]
    )
  end
  
  # set the update delay of LittleWire's i2c module
  def delay= update_delay
    @wire.control_transfer(function: :i2c_update_delay, wValue: update_delay.to_i)
  end
end
