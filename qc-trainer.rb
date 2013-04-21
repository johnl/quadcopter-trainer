# encoding: UTF-8
require 'serialport'
require 'gosu'

class Player
  def initialize(window)
    @window = window
    @image = Gosu::Image.new(@window, "qc.png", false)
    @x = (@window.width / 2) - @image.width / 2
    @y = (@window.height / 2) - @image.height / 2
    @angle = @vel_rot = @vel_x = @vel_y = 0.0
  end

  def update(throttle, yaw, roll, pitch)
    @angle += yaw / 160

    # rotational velocity
    @angle += @vel_rot
    @vel_rot += 0.01 if @vel_rot < 0
    @vel_rot -= 0.01 if @vel_rot > 0

    # roll and putch velocity
    @vel_x += Gosu::offset_x(@angle+90, roll / 400)
    @vel_y += Gosu::offset_y(@angle+90, roll / 400)
    @vel_x += Gosu::offset_x(@angle+180, pitch / 400)
    @vel_y += Gosu::offset_y(@angle+180, pitch / 400)

    @vel_x += 0.01 if @vel_x < 0
    @vel_x -= 0.01 if @vel_x > 0
    @vel_y += 0.01 if @vel_y < 0
    @vel_y -= 0.01 if @vel_y > 0

    @x += @vel_x
    @y += @vel_y
    @x %= @window.width
    @y %= @window.height
  end

  def draw
    @image.draw_rot(@x + (@image.width / 2), @y + (@image.height / 2), 1, @angle)

    # Draw the aircraft as it rolls over the screen
    if @x + @image.width > @window.width or @y + @image.height > @window.height
      xolap = (@x + @image.width) % @window.width
      yolap = (@y + @image.height) % @window.height
      @image.draw_rot((xolap - @image.width) + (@image.width / 2), (yolap - @image.height) + (@image.width / 2), 1, @angle)
    end
  end

  # Simulate the aircraft clipping the ground or being hit by some
  # wind or somethin
  def perturb!
    @vel_x += (-100 + rand(200)) / 10
    @vel_y += (-100 + rand(200)) / 10
    @angle += (-60 + rand(120))
    @vel_rot += (-300 + rand(600)) / 100
  end
end

class GameWindow < Gosu::Window
  class NoApmFound < StandardError ; end


  def initialize()
    super Gosu::screen_width, Gosu::screen_height, false
    self.caption = "Quadcopter trainer"
    @frame = 0
    @player = Player.new(self)
    begin
      connect_to_apm
      @state = :calibrate
      sleep 2
    rescue NoApmFound => e
      @state = :play
      calibrate
    end
  end

  def calibrate
    [:throttle, :yaw, :roll, :pitch].each do |k|
      eval("@#{k} = 0 if @#{k}.nil?")
      eval("@max_#{k} = 1 if @max_#{k}.nil?")
      eval("@min_#{k} = -1 if @min_#{k}.nil?")
      eval("@max_#{k} = [@max_#{k}, @#{k}].max")
      eval("@min_#{k} = [@min_#{k}, @#{k}].max")
    end
  end

  def update
    @frame += 1
    process_apm_input
    send("update_#{@state}")
  end

  def update_play
      throttle = (@throttle.to_f - @min_throttle).to_f / @max_throttle * 100
      yaw = @yaw.to_f / @max_yaw * 100
      roll = @roll.to_f / @max_roll * 100
      pitch = @pitch.to_f / @max_pitch * 100
      @player.update throttle, yaw, roll, pitch

      if (@frame % (60 * 45)) == 0 and rand(2) == 0
        @player.perturb!
      end
  end

  def update_calibrate
    calibrate
  end

  def draw
    @player.draw
  end

  def button_down(id)
    close if id == Gosu::KbEscape
    send("#{@state}_button_down", id)
  end

  def button_up(id)
    send("#{@state}_button_up", id)
  end

  def calibrate_button_down(id)
    @state = :play if id == Gosu::KbSpace
  end

  def calibraete_button_up(id)
  end

  def play_button_down(id)
    case id
    when Gosu::KbLeft
      @roll = -1
    when Gosu::KbRight
      @roll = 1
    when Gosu::KbUp
      @pitch = -1
    when Gosu::KbDown
      @pitch = 1
    when Gosu::KbA
      @yaw = -1
    when Gosu::KbS
      @yaw = 1
    end
  end

  def play_button_up(id)
    case id
    when Gosu::KbLeft
      @roll = 0
    when Gosu::KbRight
      @roll = 0
    when Gosu::KbUp
      @pitch = 0
    when Gosu::KbDown
      @pitch = 0
    when Gosu::KbA
      @yaw = 0
    when Gosu::KbS
      @yaw = 0
    when Gosu::KbSpace
      @player.perturb!
    end
  end

  def connect_to_apm
    @apm_connected = false
    device = Dir.glob('/dev/serial/by-id/*Arduino_Mega*').first
    if device.nil?
      raise NoApmFound, "No ArduPilot device found"
    end
    puts device
    @apm = SerialPort.open(device, :baud => 115200)
    @apm.set_encoding("BINARY")
    puts "Connecting to ArduPilot..."
    sleep 5
    @apm.write "\r\r\rtest\rradio\r"
    @apm.sync
    @apm_connected = true
  end

  def process_apm_input(max_lines = nil)
    return unless @apm_connected
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

