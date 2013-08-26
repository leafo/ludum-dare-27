
{graphics: g} = love
import floor from math

line_height = 8

ez_approach = (val, target, dt) ->
  approach val, target, (math.abs(val - target) + 1) * dt * 10

export ^


class Stage
  new: (@game) =>
    @hud = @make_hud!
    @timer = Timer!

    @particles = DrawList!
    @entities = DrawList!
    @done = false
    @shroud = 255

    @entities\add Sequence ->
      tween @, 0.2, shroud: 0

  make_hud: => Hud @

  update: (dt) =>
    @entities\update dt, @
    @particles\update dt
    @hud\update dt, @

    @timer\update dt unless @locked

    if @timer.time == 0 and not @locked
      @locked = true
      @entities\add Sequence ->
        wait 1.0
        tween @, 1.0, shroud: 255
        @done = true

  draw: =>
    @entities\draw!
    @particles\draw!

  draw_top: =>
    if @shroud > 0
      @game.viewport\draw { 20,20,20, @shroud }

  collides: =>
    false

class Timer
  time: 10

  draw: (x,y) =>
    old_font = g.getFont!
    g.setFont fonts.number_font
    p tostring(@), x, y

    g.setFont old_font

  update: (dt) =>
    @time -= dt
    @time = 0 if @time < 0
    true

  reset: =>
    @time = 10

  __tostring: =>
    "0:%02d"\format math.ceil(@time)

class Hud
  new: (@stage) =>
    @inventory = @stage.game.inventory

    for key, val in pairs @inventory
      @[key] = val

  draw: =>
    v = @stage.game.viewport

    g.push!
    g.translate 43, 1

    p @stage.name, 0, 0
    p "Money: $#{floor @money}", 0, line_height
    g.pop!

    g.push!
    offset = v.w / 3
    g.translate 0, v.h - line_height

    p "Steak: #{floor @steak}", 0, 0
    p "Pasta: #{floor @pasta}", offset, 0
    p "Soda: #{floor @soda}", offset * 2, 0

    g.pop!

    @stage.timer\draw 0, 0

  update: (dt) =>
    for key in pairs @inventory
      @[key] = ez_approach @[key], @inventory[key], dt

    true


class HorizBar
  color: { 255, 128, 128, 128 }
  border: true
  padding: 1
  tween_speed: 1

  new: (@w, @h, @value=0.5)=>
    @display_value = @value

  update: (dt) =>
    @display_value = ez_approach @display_value, @value, @tween_speed * dt / 5
    true

  draw: (x, y) =>
    g.push!
    val = @display_value

    if @border
      COLOR\push 255,255,255
      g.setLineWidth 0.6
      g.rectangle "line", x, y, @w, @h

      COLOR\push @color
      w = val * (@w - @padding*2)

      g.rectangle "fill", x + @padding, y + @padding, w, @h - @padding*2
      COLOR\pop 2
    else
      COLOR\push @color
      w = val * @w
      g.rectangle "fill", x, y, w, @h
      COLOR\pop!

    g.pop!

class RevealString extends Sequence
  new: (@str, @x, @y, rate=0.05) =>
    @chr = 0

    super ->
      while @chr < #@str
        @chr += 1
        wait rate

      @done = true

      while true
        wait 100

  draw: =>
    p @str\sub(1, @chr), @x, @y


{ :Stage, :RevealString, :HorizBar, :Timer, :Hud }

