# encoding: UTF-8
require 'serialport'
require 'gosu'

class Player
  def initialize(window)
    @window = window
    @image = Gosu::Image.new(@window, "qc.png", false)
    @x = @y = 350
    @angle = @vel_x = @vel_y = 0
    @score = 0
  end

  def update(throttle, yaw, roll, pitch)
    @angle += yaw / 150
    @vel_x += Gosu::offset_x(@angle+90, roll / 400)
    @vel_y += Gosu::offset_y(@angle+90, roll / 400)
    @vel_x += Gosu::offset_x(@angle+180, pitch / 400)
    @vel_y += Gosu::offset_y(@angle+180, pitch / 400)

    @x += @vel_x
    @y += @vel_y
    @x %= @window.width
    @y %= @window.height
  end

  def draw
    @image.draw_rot(@x, @y, 1, @angle)
  end
end

class GameWindow < Gosu::Window
  def initialize()
    super 1440, 800, false
    self.caption = "Quadcopter trainer"
    @yaw = 0
    @player = Player.new(self)
    @frame = 0
    connect_to_apm
    puts "Move your radio sticks around for a few seconds"
    1000.times do
      process_apm_input(max_lines = 1)
      @max_throttle = [@max_throttle || @throttle, @throttle].max
      @min_throttle = [@min_throttle || @throttle, @throttle].min
      @max_yaw = [@max_yaw || @yaw, @yaw].max
      @min_yaw = [@min_yaw || @yaw, @yaw].min
      @max_roll = [@max_roll || @roll, @roll].max
      @min_roll = [@min_roll || @roll, @roll].min
      @max_pitch = [@max_pitch || @pitch, @pitch].max
      @min_pitch = [@min_pitch || @pitch, @pitch].min
      putc "."
    end
    puts "Done"
    sleep 2
    process_apm_input
  end

  def update
    process_apm_input
    throttle = (@throttle.to_f - @min_throttle).to_f / @max_throttle * 100
    yaw = @yaw.to_f / @max_yaw * 100
    roll = @roll.to_f / @max_roll * 100
    pitch = @pitch.to_f / @max_pitch * 100
    @player.update throttle, yaw, roll, pitch
  end

  def draw
    @player.draw
  end

  def button_down(id)
    if id == Gosu::KbEscape
      close
    end
  end

  def connect_to_apm
    device = Dir.glob('/dev/serial/by-id/*Arduino_Mega*').first
    puts device
    @apm = SerialPort.open(device, :baud => 115200)
    @apm.set_encoding("BINARY")
    puts "Connecting to ArduPilot..."
    sleep 5
    @apm.write "\r\r\rtest\rradio\r"
    @apm.sync
  end

  def process_apm_input(max_lines = nil)
    return if IO.select([@apm],[],[],nil) == nil
    i = 0
    @apm.each_line do |line|
      i += 1
      if max_lines and i > max_lines
        next
      end
      next if line.nil?
      if line =~ /^IN  1/
        radios = line.scan(/([0-9]{1}): ([0-9-]+)/)
        next if radios.size < 7
        @throttle = radios[2].last.to_i
        @yaw = radios[3].last.to_i
        @roll = radios[0].last.to_i
        @pitch = radios[1].last.to_i
      end
    end
  end
end

window = GameWindow.new
window.show

