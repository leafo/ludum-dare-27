
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

    with @entities = DrawList!
      \add @hud

  make_hud: => Hud @

  update: (dt) =>
    @entities\update dt, @

  draw: =>
    @entities\draw!

  is_done: =>
    @timer.time == 0

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

    @stage.timer\update dt
    true


class HorizBar
  color: { 255, 128, 128, 128 }
  border: true
  padding: 1

  new: (@w, @h, @value=0.5)=>

  update: (dt) =>

  draw: (x, y) =>
    g.push!
    g.setColor 255,255,255

    if @border
      g.setLineWidth 0.6
      g.rectangle "line", x, y, @w, @h

      g.setColor @color
      w = @value * (@w - @padding*2)

      g.rectangle "fill", x + @padding, y + @padding, w, @h - @padding*2
    else
      g.setColor @color
      w = @value * @w
      g.rectangle "fill", x, y, w, @h

    g.pop!
    g.setColor 255,255,255,255

