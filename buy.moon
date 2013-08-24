
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
  w: 5
  h: 5
  speed: 10
  color: { 222, 84, 208 }

  stunned: false

  new: (@x, @y) =>
    @vel = Vec2d!
    @accel = Vec2d!
    @behave!

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
    -- @seq = (pick_one @behavior_1, @behavior_2) @
    @seq = @behavior_1!

  behavior_1: =>
    print "behavior 1"
    Sequence ->
      @applied = Vec2d.random! * rand(90, 110)
      apply_force @, rand(0.1, 0.2), @applied
      @applied = nil
      wait wait 0.8, 1.2
      again!

  update: (dt, stage) =>
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

    cx, cy = @fit_move @vel[1] * dt, @vel[2] * dt, stage

    if cx
      @applied[1] = -@applied[1] if @applied
      @vel[1] = -@vel[1] / 2

    if cy
      @applied[2] = -@applied[2] if @applied
      @vel[2] = -@vel[2] / 2

    true

  draw: =>
    if @shake_x
      g.push!
      g.translate @shake_x, @shake_y

    super @stunned and {255,0,0} or @color

    if @shake_x
      g.pop!

    -- p "%0.2f"\format(tostring @vel\len!), @x, @y

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

  add_people: (num=30) =>
    return for i=1,num
      with p = Person @person_drop\random_point!
        while @collides p
          print "reputting..."
          p.x, p.y = @person_drop\random_point!

        @entities\add p

  collides: (thing) =>
    for v in *@vendors
      if v\touches_box thing
        return true

    not @game.viewport\contains_box thing

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
      -- \add BoxSelector @game.viewport

