
{graphics: g} = love

export ^

class Stage
  timer_x: 10
  timer_y: 10

  new: =>
    @timer = Timer @timer_x, @timer_y

  is_done: =>
    @timer.time == 0

class Timer
  time: 10

  new: (@x, @y) =>

  draw: =>
    old_font = g.getFont!
    g.setFont fonts.number_font
    g.print tostring(@), @x, @y

    g.setFont old_font

  update: (dt) =>
    @time -= dt * 8
    @time = 0 if @time < 0
    true

  reset: =>
    @time = 10

  __tostring: =>
    "0:%02d"\format math.ceil(@time)


