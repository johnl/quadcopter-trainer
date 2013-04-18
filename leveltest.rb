# encoding: UTF-8
require 'serialport'

device = Dir.glob('/dev/serial/by-id/*Arduino_Mega*').first
puts device
p = SerialPort.open(device, :baud => 115200)
p.set_encoding("BINARY")
state = :init
buf = ""
puts "Connecting to ArduPilot..."
sleep 5
p.write "\r\r\rtest\rradio\r"
p.sync
loop do
  p.each_line do |line|
    next if line.nil?
    if line =~ /^IN  1/
      radios = line.scan(/([0-9]{1}): ([0-9]+)/)
      next if radios.size < 7
      #    puts radios.inspect
      puts "throttle: #{radios[2].last}"
    end
  end
  IO.select([p])
end

p.close
