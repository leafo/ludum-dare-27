
{graphics: g} = love

export ^

class Player extends Entity
  speed: 80
  w: 10
  h: 10

  new: (x,y) =>
    super x, y

  update: (dt) =>
    dir = movement_vector!
    @move unpack dir * @speed * dt
    true

class BuyStage extends Stage
  new: =>
    super!
    @player = Player 100, 100

    @entities = DrawList!
    @entities\add @player
    @entities\add @timer

  collides: =>
    false

  update: (dt) =>
    @entities\update dt, @

  draw: =>
    @entities\draw!
    g.print "Buy Stage", 100, 10

