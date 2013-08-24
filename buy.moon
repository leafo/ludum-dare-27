
{graphics: g, :keyboard} = love


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


class Person extends Entity
  w: 5
  h: 5
  speed: 10

  color: { 222, 84, 208 }

  new: (@x, @y) =>
    (pick_one @behavior_1, @behavior_2) @

  behavior_1: =>
    print "behavior 1"
    @seq = Sequence ->
      speed = rand 8, 12
      dist = rand 8,13
      step = Vec2d.random dist

      tween @, dist / speed, x: @x + step[1], y: @y + step[2]

      wait rand 0.6, 1.2
      again!

  behavior_2: =>
    print "behavior 2"
    @seq = Sequence ->
      dir = Vec2d.random!

      for i = 1, math.random 5, 10
        heading = dir\random_heading 90, random_normal!
        heading = heading * 4
        tween @, 0.2, { x: @x + heading[1], y: @y + heading[2] }, lerp

      again!

  update: (dt, stage) =>
    @seq\update dt
    true

  draw: =>
    super @color


export ^

class Vendor extends Box
  w: 20
  h: 20
  cooloff: 0.05

  price: 8

  new: (@x, @y, @type) =>
    @buy_radius = @scale 1.8, 1.8, true

  update: (dt, stage) =>
    @cooloff -= dt
    @cooloff = 0 if @cooloff < 0
    true

  buy: (stage) =>
    return unless @cooloff == 0
    @cooloff = @@cooloff
    inventory = stage.game.inventory

    if inventory.money < @price
      print "NO MONEY"
      return

    print "BUYING #{@type} for #{@price}"
    stage.game.inventory[@type] += 1
    stage.game.inventory.money -= @price

  draw: =>
    if @active
      Box.draw @, {188,200,123}
    else
      Box.draw @, {128,200,83}

    @active = false

class BuyStage extends Stage
  name: "Buy Stage"
  person_drop: Box  11, 18, 176, 120

  on_key: (char) =>
    if char == " "
      for vendor in *@vendors
        if @player\touches_box vendor.buy_radius
          vendor\buy @

  add_people: (num=10) =>
    people = for i=1,num
      with p = Person @person_drop\random_point!
        @entities\add p

  new: (...) =>
    super ...
    @player = Player 100, 100
    @vendors = {
      Vendor 10, 50, "steak"
      Vendor 80, 50, "pasta"
      Vendor 150, 30, "soda"
    }

    @people = @add_people!

    with @entities
      \add @player
      \add Vendor 10, 50
      \add_all @vendors
      \add BoxSelector @game.viewport

