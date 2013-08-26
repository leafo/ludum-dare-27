
{graphics: g} = love

export *

class MoneyParticle extends Particle
  lazy sprite: -> Spriter "images/tiles.png", 10, 10

  draw: =>
    p = @p!

    COLOR\pusha 255 * @fade_out 0.5
    @sprite\draw "9,130,20,14", @x, @y
    COLOR\pop!

class MoneyEmitter extends Emitter
  count: 1

  new: (amt, price, world, x,y,duration) =>
    count = switch price
      when 8
        3
      when 5
        2
      else
        1

    super world, x, y, duration, count
    @world.particles\add NumberParticle @x, @y, "+#{amt}"

  make_particle: (x,y) =>
    power = rand 140, 160
    dir = Vec2d(0, -power)\random_heading 40

    MoneyParticle x,y, dir, Vec2d(0, 400)


class NumberParticle extends Particle
  life: 0.8
  spread: 20
  dir: Vec2d(2, -1)\normalized!

  new: (x, y, number) =>
    super x, y
    @number = tostring number

    @y -= 10
    @number = tostring number
    @vel = @dir\random_heading(@spread) * 60
    @accel = Vec2d 0, 100

    @s = 0.5
    @drot = (random_normal! - 0.5) * 5
    @rot = 0
    @a = 1

  update: (dt) =>
    t = 1 - @life / @@life
    @rot += dt * @drot

    if t < 0.2
      @s += dt * 5
    elseif t > 0.8
      @s -= dt

    if t > 0.5
      @a = 1 - (t - 0.5) / 0.5

    super dt

  draw: =>
    COLOR\pusha @a * 255

    g.push!
    g.translate @x, @y
    g.print @number, 0,0, @rot, @s, @s, 4, 4
    g.pop!

    COLOR\pop!
