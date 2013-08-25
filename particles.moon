
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
  count: 2

  new: (@price, ...) =>
    super ...

  make_particle: (x,y) =>
    power = rand 140, 160
    dir = Vec2d(0, -power)\random_heading 40

    MoneyParticle x,y, dir, Vec2d(0, 400)

