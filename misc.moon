
{graphics: g} = love
import floor from math

line_height = 8

ez_approach = (val, target, dt) ->
  approach val, target, (math.abs(val - target) + 1) * dt * 10

export ^

class Stage
  new: (@game) =>
    @hud = Hud @
    @timer = Timer!

    with @entities = DrawList!
      \add @hud

  update: (dt) =>
    @entities\update dt, @

  draw: =>
    @entities\draw!

  is_done: =>
    @timer.time == 0

  collides: =>
    false

class Timer
  time: 99

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

