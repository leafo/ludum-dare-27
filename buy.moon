
{graphics: g, :keyboard} = love

Sequence.default_scope.shake = (thing, total_time, mx=5, my=5, speed=10, decay_to=0) ->
  time = total_time

  while time > 0
    time -= coroutine.yield!
    decay = math.min(math.max(time, decay_to), 1)
    thing.shake_x = decay * mx * math.sin(time*10*speed)
    thing.shake_y = decay * my * math.cos(time*10*speed)

  thing.shake_x = nil
  thing.shake_y = nil

-- a tween that applies a delta to value instead of constant
-- probably not going to need this
Sequence.default_scope.tween_delta = (thing, time, diffs, step=smoothstep) ->
  t = 0
  last_frame = { k, 0 for k in pairs diffs }

  while t < 1.0
    for key, finish in pairs diffs
      new_val = step 0, finish, t
      thing[key] += new_val - last_frame[key]
      last_frame[key] = new_val

    t += coroutine.yield! / time

  -- push left over time
  leftover = t - 1.0
  if leftover > 0
    coroutine.yield "more", leftover

-- thing must have @vel
Sequence.default_scope.apply_force = (thing, time, force, target="vel") ->
  while time > 0
    dt = coroutine.yield!
    thing[target][1] += force[1] * dt
    thing[target][2] += force[2] * dt
    time -= dt

  if time < 0
    coroutine.yield "more", -time

class Player extends Entity
  speed: 280
  max_speed: 80
  w: 10
  h: 10

  new: (x,y) =>
    super x, y
    @vel = Vec2d(0,0)
    @accel = Vec2d(0,0)

  update: (dt, stage) =>
    decel = @speed / 1.5 * dt

    if @hit_seq
      @hit_seq\update dt
    else
      @accel = movement_vector!

    if @accel\is_zero!
      dampen_vector @vel, decel
    else
      if @accel[1] == 0
        -- not moving in x, shrink it
        @vel[1] = dampen @vel[1], decel
        nil
      else
        if (@accel[1] < 0) == (@vel[1] > 0)
          @accel[1] *= 2

      if @accel[2] == 0
        -- not moving in y, shrink it
        @vel[2] = dampen @vel[2], decel
      else
        if (@accel[2] < 0) == (@vel[2] > 0)
          @accel[2] *= 2


    @vel\adjust unpack @accel * dt * @speed
    @vel\cap @max_speed

    cx, cy = @fit_move @vel[1] * dt, @vel[2] * dt, stage

    if cx
      @vel[1] = 0
      @accel[1] = 0

    if cy
      @vel[2] = 0
      @accel[2] = 0

    -- see if hitting person
    unless @hit_seq
      for p in *stage.people
        continue if p.hit_seq
        if p\touches_box @
          p\take_hit @, stage
          @take_hit p, stage

    true

  take_hit: (thing, stage) =>
    @hit_seq = Sequence ->
      print "player stunned"
      @accel = Vec2d!
      dir = (Vec2d(@center!) - Vec2d(thing\center!))\normalized! * 3000
      apply_force @, 0.1, dir
      @vel = Vec2d!
      shake @, 0.2, 10, 10
      @hit_seq = nil

  draw: =>
    if @shake_x
      g.push!
      g.translate @shake_x, @shake_y

    super!

    if @shake_x
      g.pop!


class Person extends Entity
  lazy sprite: -> Spriter "images/characters.png", 16, 32

  w: 4
  h: 6

  ox: 2, oy: 13

  speed: 10
  color: { 222, 84, 208 }

  stunned: false

  new: (@x, @y) =>
    @vel = Vec2d!
    @accel = Vec2d!
    @behave!

    with @sprite
      @anim = StateAnim "stand", {
        stand: \seq { "90,81,8,19", "101,81,8,19" }, 0.4
        walk_left: \seq { "112,81,8,19", "132,81,8,19" }, 0.3
        walk_right: \seq { "112,81,8,19", "132,81,8,19" }, 0.3, true
        stunned: \seq { "140,81,10,19" }
      }

  take_hit: (thing, stage) =>
    return if @stunned
    @stunned = true

    @seq = Sequence ->
      @applied = (Vec2d(@center!) - Vec2d(thing\center!))\normalized! * 1000
      apply_force @, 0.1, @applied
      @applied = nil
      shake @, 0.2, 10, 10
      wait 0.5
      @stunned = false

      @behave!

  behave: =>
    @seq = @behavior_1!

  behavior_1: =>
    Sequence ->
      if math.random! < 0.5
        -- stand for a moment
        @vel[1] = 0
        @vel[2] = 0
        wait rand 0.8, 1.2

      @applied = Vec2d.random! * rand(90, 110)
      apply_force @, rand(0.1, 0.2), @applied
      @applied = nil
      wait rand 0.8, 1.2

      again!

  update: (dt, stage) =>
    @anim\update dt
    @seq\update dt if @seq

    @vel\adjust unpack @accel * dt

    -- repel powerup
    -- repel = Vec2d(@center!) - Vec2d(stage.player\center!)
    -- dist = repel\len!
    -- dist = 30 - dist

    -- if dist > 0
    --   @vel\adjust unpack repel\normalized! * dt * 100

    if not @applied
      speed = @vel\len!
      damp = dt * 2 * speed / 3
      if @stunned
        damp *= 10

      dampen_vector @vel, damp

    if @stunned
      @anim\set_state "stunned"
    else
      if @vel\is_zero!
        @anim\set_state "stand"

      if @vel[1] < 0
        @anim\set_state "walk_left"

      if @vel[1] > 0
        @anim\set_state "walk_right"

    cx, cy = @fit_move @vel[1] * dt, @vel[2] * dt, stage

    if cx
      @applied[1] = -@applied[1] if @applied
      @vel[1] = -@vel[1] / 2

    if cy
      @applied[2] = -@applied[2] if @applied
      @vel[2] = -@vel[2] / 2

    true

  draw_shadow: =>
    COLOR\push 0,0,0, 20
    g.rectangle "fill", @x - 3, @y + 4, 10, 3
    COLOR\pop!

  draw: =>
    if @shake_x
      g.push!
      g.translate @shake_x, @shake_y

    -- super @stunned and {255,0,0} or @color
    @anim\draw @x - @ox, @y - @oy

    if @shake_x
      g.pop!

    -- p "%0.2f"\format(tostring @vel\len!), @x, @y

export ^

class Vendor extends Box
  lazy {
    tiles: -> Spriter "images/tiles.png", 10, 10
    sprite: -> Spriter "images/characters.png", 10, 10
  }

  w: 18
  h: 11

  cooloff: 0.05

  price: 8

  new: (@x, @y, @type) =>
    @buy_radius = @scale 1.8, 1.8, true
    @anim = @sprite\seq { "89,60,10,10", "100,60,10,10" }, random_normal!
    @anim\update math.random!

  update: (dt, stage) =>
    @anim\update dt
    @cooloff -= dt
    @cooloff = 0 if @cooloff < 0
    true

  buy: (stage) =>
    return if stage.player.hit_seq
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
    @tiles\draw "34,77,12,5", @x + 3, @y
    @anim\draw @x + 4, @y - 3
    @tiles\draw "10,64,20,26", @x - 1, @y - 13
    -- Box.draw @, {0,0,0, 200}

  draw_shadow: =>
    COLOR\push 0,0,0, 30
    g.rectangle "fill", @x - 1, @y + 2, @w + 2, @h
    COLOR\pop!

class BuyStage extends Stage
  name: "Buy Stage"

  person_drop: Box 29, 49, 141, 71
  bounding_box: Box 19, 39, 162, 92

  on_key: (char) =>
    if char == " "
      for vendor in *@vendors
        if @player\touches_box vendor.buy_radius
          vendor\buy @

  make_people: (num=10) =>
    return for i=1,num
      with p = Person @person_drop\random_point!
        while @collides p
          p.x, p.y = @person_drop\random_point!

  collides: (thing) =>
    for v in *@vendors
      if v\touches_box thing
        return true

    not @bounding_box\contains_box thing

  draw: =>
    @map\draw @viewport
    -- draw shadows
    for item in *@units
      if item.draw_shadow
        item\draw_shadow!

    super!

  new: (...) =>
    super ...
    @player = Player 100, 100

    @vendors = {
      Vendor 31, 37, "steak"
      Vendor 151, 37, "pasta"
      Vendor 31, 97, "soda"
    }

    @people = @make_people!

    @units = DrawList!
    @units.draw = @units.draw_sorted

    with @units
      \add @player
      \add_all @people
      \add_all @vendors

    @map = TileMap.from_tiled "maps.buy"

    with @entities
      \add @units
      -- \add BoxSelector @game.viewport

{ :Player, :Person, :Vendor, :BuyStage }
