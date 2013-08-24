
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


class Vendor extends Box
  w: 20
  h: 20

  new: (@x, @y) =>

  update: (dt) =>
    true

  draw: =>
    Box.draw @, {128,200,83}

class BuyStage extends Stage
  new: =>
    super!
    @player = Player 100, 100

    with @entities = DrawList!
      \add @player
      \add @timer
      \add Vendor 10, 50
      \add Vendor 80, 50

  collides: =>
    false

  update: (dt) =>
    @entities\update dt, @

  draw: =>
    @entities\draw!
    p "Buy Stage", 100, 10

