
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
  money: 999

  steak: 0
  pasta: 0
  soda: 0
  
  new: (@stage) =>
    @display_money = @money

    @display_steak = @steak
    @display_pasta = @pasta
    @display_soda = @soda

  draw: =>
    v = @stage.game.viewport

    g.push!
    g.translate 43, 1

    p @stage.name, 0, 0
    p "Money: $#{floor @display_money}", 0, line_height
    g.pop!

    g.push!
    offset = v.w / 3
    g.translate 0, v.h - line_height

    p "Steak: #{floor @display_steak}", 0, 0
    p "Pasta: #{floor @display_pasta}", offset, 0
    p "Soda: #{floor @display_soda}", offset * 2, 0

    g.pop!

    @stage.timer\draw 0, 0

  update: (dt) =>
    @display_money = ez_approach @display_money, @money, dt
    @stage.timer\update dt
    true

