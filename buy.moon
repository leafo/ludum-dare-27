
{graphics: g, :keyboard} = love

export ^

class Player extends Entity
  speed: 80
  w: 10
  h: 10

  new: (x,y) =>
    super x, y

  update: (dt, stage) =>
    dir = movement_vector!
    @move unpack dir * @speed * dt
    true

class Vendor extends Box
  w: 20
  h: 20
  cooloff: 0.1

  new: (@x, @y, @type) =>
    @buy_radius = @scale 1.8, 1.8, true

  update: (dt, stage) =>
    @cooloff -= dt
    @cooloff = 0 if @cooloff < 0
    true

  buy: (stage) =>
    return unless @cooloff == 0
    @cooloff = @@cooloff
    print "BUYING #{@type}"

  draw: =>
    if @active
      Box.draw @, {188,200,123}
    else
      Box.draw @, {128,200,83}

    @active = false

class BuyStage extends Stage
  name: "Buy Stage"

  on_key: (char) =>
    if char == " "
      for vendor in *@vendors
        if @player\touches_box vendor.buy_radius
          vendor\buy @
          @hud.money -= 55

  new: (...) =>
    super ...
    @player = Player 100, 100
    @vendors = {
      Vendor 10, 50, "steak"
      Vendor 80, 50, "pasta"
      Vendor 150, 30, "soda"
    }

    with @entities
      \add @player
      \add Vendor 10, 50
      \add_all @vendors

