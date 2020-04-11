# frozen_string_literal: true

# jscottpilgrim, control_panel by monkstone

require 'propane'


class JuliaBrot < Propane::App
  load_library :control_panel
  attr_reader :x_center, :x_range, :y_center, :zoom
  DEFAULT = 4.0

  def settings
    size 1000, 1000, P2D
    control_panel do |c|
      c.look_feel 'Nimbus'
      c.title 'Control Panel'
      c.button :reset! # see method below
      c.slider :x_range, 1.0..10.0, DEFAULT
      c.slider :x_center, -3.0..3.0, 0.0
      c.slider :y_center, -3.0..3.0, 0.0
      c.checkbox :edp_enable, false
      c.menu :mode, %i[mandelbrot julia julia_loop]
    end
    @y_range = @x_range * height / width
    @zoom = @x_range / width

    @julia_param = [0.1994, -0.613]

    # length of julia loop in frames
    @loop_length = 120
  end

  def update_zoom
    @zoom = x_range / width
    @y_range = x_range * height / width
  end

  def setup
    sketch_title 'JuliaBrot'
    # frame_rate 20

    # initialize some parameters
    # @mode = :mandelbrot
    @line_start = [0, 0]
    @julia_loop_begin = [0, 0]
    @julia_loop_end = [0, 0]
    @loop_time = 0
    @paused = false
    @edp_enable = false

    # load shaders
    @mandelbrot_shader = load_shader data_path('MandelbrotDE.glsl')
    @mandelbrot_shader.set 'resolution', width.to_f, height.to_f
    @mandelbrot_shader2 = load_shader data_path('MandelbrotDE-double.glsl')
    @mandelbrot_shader2.set 'resolution', width.to_f, height.to_f

    @julia_shader = load_shader data_path('JuliaDE.glsl')
    @julia_shader.set 'resolution', width.to_f, height.to_f
    @julia_shader2 = load_shader data_path('JuliaDE-double.glsl')
    @julia_shader2.set 'resolution', width.to_f, height.to_f
    reset!
  end

  def mandelbrot_draw
    s = @edp_enable ? @mandelbrot_shader2 :  @mandelbrot_shader
    s.set 'center', x_center, y_center
    s.set 'zoom', zoom
    shader s
    rect 0, 0, width, height
    reset_shader
  end

  def julia_draw
    s = @edp_enable ? @julia_shader2 : @julia_shader
    s.set 'center', x_center, y_center
    s.set 'zoom', @zoom
    s.set 'juliaParam', @julia_param[0], @julia_param[1]
    shader s
    rect 0, 0, width, height
    reset_shader
  end

  def julia_loop_draw
    # calculate julia param with interpolation from julia_loop_begin to julia_loop_end using loop_time
    real_dif = @julia_loop_end[0] - @julia_loop_begin[0]
    imag_dif = @julia_loop_end[1] - @julia_loop_begin[1]
    m = Math.sin((TWO_PI / (@loop_length * 2)) * @loop_time)
    real_offset = m * real_dif
    imag_offset = m * imag_dif
    r = @julia_loop_begin[0] + real_offset
    i = @julia_loop_begin[1] + imag_offset
    @julia_param = [r, i]
    # increment time for next frame
    @loop_time = @loop_time.succ
    # reset loop time when cycle is complete
    @loop_time = 0 if @loop_time == @loop_length
    julia_draw
  end

  def draw
    update_zoom
    case @mode
    when :mandelbrot
      mandelbrot_draw
    when :julia
      julia_draw
    when :julia_loop
      julia_loop_draw
    end
    # show where line for julia loop would be drawn when clicked
    if @line_drawing
      stroke 100, 0, 0
      stroke_weight 3
      line @line_start[0], @line_start[1], mouse_x, mouse_y
      no_stroke
    end
  end

    def reset!
      # reset to standard view mandelbrot
      @center = [0.0, 0.0]
      @x_range = DEFAULT
      @y_range = x_range * height / width
      @zoom = x_range / width
      @mode = :mandelbrot
      @line_drawing = false
      @line_start = [0, 0]
      @julia_loop_begin = [0, 0]
      @julia_loop_end = [0, 0]
      @loop_time = 0
      @pause = false
    end

    def paused
      # pause julia loop on frame
      if @mode == :julia_loop
        @mode = :julia
        @pause = true
      elsif @pause
        @mode = :julia_loop
        @pause = false
      end
    end

    def mouse_clicked
      if @line_drawing
        # select ending point for julia loop
        x_min = x_center - @x_range / 2.0
        x_max = x_center + @x_range / 2.0
        y_min = y_center - @y_range / 2.0
        y_max = y_center + @y_range / 2.0
        @julia_loop_end = [map1d(mouse_x, (0...width), (x_min..x_max)), map1d(mouse_y, (0..height), (y_max..y_min))]
        @line_drawing = false
        @center_x = 0
        @center_y = 0
        @x_range = DEFAULT
        @y_range = @x_range * height / width
        @zoom = @x_range / width
        @mode = :julia_loop
        @loop_time = 0
      else
        if @mode == :mandelbrot
          # from mandelbrot use mouse to choose seed(s) for julia set(s)
          if mouse_button == RIGHT
            # start line for julia loop
            @line_drawing = true
            @line_start = [mouse_x, mouse_y]
            x_min = x_center - @x_range / 2.0
            x_max = x_center + @x_range / 2.0
            y_min = y_center - @y_range / 2.0
            y_max = y_center + @y_range / 2.0
            @julia_loop_begin = [map1d(mouse_x, (0...width), (x_min..x_max)), map1d(mouse_y, (0..height), (y_max..y_min))]
          else
            # left click for static julia set
            x_min = x_center - @x_range / 2.0
            x_max = x_center + @x_range / 2.0
            y_min = y_center - @y_range / 2.0
            y_max = y_center + @y_range / 2.0
            @julia_param = [map1d(mouse_x, (0...width), (x_min..x_max)), map1d(mouse_y, (0..height), (y_max..y_min))]
            @center_x = 0
            @center_y = 0
            @x_range = DEFAULT
            @y_range = @x_range * height / width
            @zoom = @x_range / width
            @mode = :julia
          end
        end
      end
    end
  end

  JuliaBrot.new
