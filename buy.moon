
{graphics: g, :keyboard} = love

Sequence.default_scope.shake = (thing, total_time, mx=5, my=5, speed=10, decay_to=0) ->
  ox, oy = thing.x, thing.y

  time = total_time
  while time > 0
    time -= coroutine.yield!
    decay = math.min(math.max(time, decay_to), 1)

    dx = decay * mx * math.sin(time*10*speed)
    dy = decay * my * math.cos(time*10*speed)

    thing.x = ox + dx
    thing.y = oy + dy


-- a tween that applies a delta to value instead of constant
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

    @move @vel[1] * dt, @vel[2] * dt

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

      dist = 15 -- TODO: shrink this with upgrade

      dir = (Vec2d(@center!) - Vec2d(thing\center!))\normalized! * dist

      tween_delta @, dist / 100, { x: dir[1], y: dir[2] }

      shake @, 0.2, 10, 10
      @hit_seq = nil


class Person extends Entity
  w: 5
  h: 5
  speed: 10

  color: { 222, 84, 208 }

  new: (@x, @y) =>
    (pick_one @behavior_1, @behavior_2) @

  take_hit: (thing, stage) =>
    return if @hit_seq

    @hit_seq = Sequence ->
      c = @color
      @color = {255, 0, 0}

      dir = (Vec2d(@center!) - Vec2d(thing\center!))\normalized! * 10
      tween @, 0.2, { x: @x + dir[1], y: @y + dir[2] }
      shake @, 0.2, 10, 10

      @color = c
      @hit_seq = nil
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
    if @hit_seq
      @hit_seq\update dt
    else
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
    return for i=1,num
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

