{graphics: g, :timer} = love

colors = {
  steak: { 250, 92, 102 }
  pasta: { 235, 199, 0 }
  soda: { 141, 74, 232 }
  gray: { 80,80,80 }
}

on_sprites = {
  steak: "40,130,10,10"
  pasta: "50,130,10,10"
  soda: "60,130,10,10"
}

off_sprites = {
  steak: "40,140,10,10"
  pasta: "50,140,10,10"
  soda: "60,140,10,10"
}

class FeedHud extends Hud
  -- box<(113, 2), (83, 12)>
  lazy {
    sprite: -> Spriter "images/tiles.png", 10, 10
    head_sprite: -> Spriter "images/head.png"
  }


  new: (...) =>
    super ...
    @health = HorizBar 70, 6

  draw: =>
    super!
    hungry_for = @stage.head.hungry_for

    g.push!
    g.translate 120, 1
    p "Satisfaction", 0,0
    @health\draw 3, 9
    g.pop!


    g.push!
    g.translate 82, 25

    @head_sprite\draw "44,68,49,38", 0,0

    w = 10
    for i, food in ipairs {"steak", "pasta", "soda"}
      hungry = hungry_for[food]

      cell = if hungry
        on_sprites[food]
      else
        off_sprites[food]

      x, y = 4 + (i - 1) * (w + 4), 4

      @sprite\draw cell, x, y

      unless hungry
        @sprite\draw "70,130,10,10", x, y

    g.pop!

  update: (dt) =>
    @health.value = @stage.head.health
    @health\update(dt)
    super dt


class Player extends Box
  lazy sprite: -> Spriter "images/characters.png", 16, 32

  speed: 100
  throw_time: -1000

  w: 8
  h: 10

  x: 20
  y: 124

  goto_pile: (pile, stage) =>
    if pile == @current_pile
      pile\throw stage if not @seq
      @on_throw pile
      return

    x,y = pile\center!
    @seq = Sequence ->
      @current_pile = pile
      len = Vec2d(x - @x, y - @y)\len!
      tween @, len / @speed, { :x, :y } -- , lerp
      pile\throw stage
      @seq = nil
      @on_throw pile

  on_throw: =>
    @throw_time = timer.getTime!
    @anim\set_state "throw"

  draw: =>
    COLOR\push 0,0,0, 120
    g.rectangle "fill", @x - 5, @y + 19, 10, 3
    COLOR\pop!

    if @anim.current_name == "throw"
      @anim\draw @x - 8, @y
    else
      @anim\draw @x - 5, @y

    -- super {100,255,100}

  update: (dt) =>
    dx = @x - @xx
    @xx = @x

    state = if dx == 0
      if timer.getTime! - @throw_time < 0.3
        "throw"
      else
        "stand"
    elseif dx < 0
      "walk_left"
    else
      "walk_right"

    @anim\set_state state

    @anim\update dt

    if @seq
      @seq\update dt

    true

  new: =>
    with @sprite
      @anim = StateAnim "stand", {
        stand: \seq { "75,33,10,21", "60,33,10,21" }, 0.4
        throw: \seq { "40,33,16,21", "22,33,16,21" }, 0.15

        walk_left: \seq { "116,33,10,21", "128,33,10,21" }, 0.3
        walk_right: \seq { "116,33,10,21", "128,33,10,21" }, 0.3, true
      }

    -- used to delta
    @xx = @x

export ^

class Head
  lazy {
    sprite: -> Spriter "images/head.png"
    puke_sprite: -> Spriter "images/puke.png", 60, 49
  }

  -- box<(104, 76), (69, 39)>
  color: { 252, 231, 178 }
  mouth_color: { 255, 80, 80, 100 }
  puke_color: { 71, 128, 78 }

  x: 110
  y: 25

  health: 0.5

  new: =>
    super
    @t = timer.getTime()
    @mouth_hitbox = Box 120, 95, 36, 30

    @hungry_for = {
      steak: true
      pasta: true
      soda: true
    }

    @puke_anim = @puke_sprite\seq { 0,1,2, 3, 4, 5, 4, 5, }, 0.1

    @seq = Sequence ->
      for k in pairs @hungry_for
        @hungry_for[k] = true

      delta = math.abs 0.5 - random_normal!
      to_hide = math.floor delta / 0.09
      to_hide = 3

      while to_hide > 0
        not_hungry = pick_one unpack [k for k,v in pairs @hungry_for when v]
        @hungry_for[not_hungry] = false
        to_hide -= 1

      wait 1
      again!

  draw: =>
    g.push!
    t = @t

    cx = @x + 30
    cy = @y + 54

    g.translate cx, cy
    g.rotate math.sin(t * 5) / 20
    g.translate -cx, -cy

    -- Box(0,0,3,3)\move_center(@x, @y)\draw {255,100,100,100}

    if @puking
      COLOR\push 234,255,199

    -- eyes
    COLOR\push 255,255,255
    g.rectangle "fill", -- left white
      @x + 12, @y + 40,
      10, 10

    g.rectangle "fill", -- left white
      @x + 40, @y + 40,
      15, 10

    COLOR\pop!
    COLOR\pop! if @puking

    -- left pupil
    @sprite\draw "64,15,5,4",
      @x + 14 + math.sin(t), @y + 44 + math.cos(1 + t * 1.2)

    -- right pupil
    @sprite\draw "75,14,6,6",
      @x + 44 + math.cos(2 + t * 0.9), @y + 44 + math.sin(3 + t * 1.1)
    -- stop eyes

    -- head and mouth
    @sprite\draw "108,22,88,120", @x, @y
    @sprite\draw "57,29,33,30",
      @x + 10, @y + 84 + math.abs(math.sin(t * 5) * 10)

    if @puking
      @puke_anim\draw @x - 21, @y + 77

    -- @mouth_hitbox\draw { 255,255,255,100 }

    g.pop!


  update: (dt) =>
    speed_mul = 1
    speed_mul = 4 if @puking

    @t += dt * speed_mul

    @puke_anim\update dt

    @health -= dt / 10
    @health = 0 if @health < 0

    @seq\update dt
    @puking\update dt if @puking
    true

  puke: =>
    @puke_anim\reset!
    @puking = Sequence ->
      print "I AM PUKING"
      wait 1.0
      @puking = nil

  eat: (food, stage) =>
    @health += 0.1
    @health = 1 if @health > 1

class Bat extends Box
  lazy sprite: -> Spriter "images/tiles.png"

  color: { 200, 188, 66 }

  x: -8
  y: -4

  w: 70
  h: 8

  wx: 70
  wy: 20

  rot: 0

  rest_rot: 2.7018146928204
  swing_rot: 1.7848146928204

  swinging: false

  swing: =>
    if @return_progress and @return_progress > 0.8
      @seq = nil

    return if @seq

    @seq = Sequence ->
      @return_progress = 0
      @swinging = true
      tween @, 0.1, rot: @swing_rot
      @swinging = false

      tween @, 0.5, rot: @rest_rot, return_progress: 1
      @seq = nil

  touches_pt: (x,y) =>
    vec = Vec2d(x,y) - Vec2d(@wx, @wy)

    r = vec\len!
    theta = vec\radians! - @rot

    local_x = r * math.cos theta
    local_y = r * math.sin theta

    super local_x, local_y

  update: (dt, stage) =>
    @rot = @rest_rot
    @seq\update dt if @seq

    true

  draw: =>
    g.push!
    g.translate @wx, @wy
    g.rotate @rot

    -- COLOR\push @color
    -- g.rectangle "fill", @x, @y, @w, @h
    -- COLOR\pop!

    @sprite\draw "10,151,70,8", @x, @y

    g.pop!


class FoodItem extends Particle
  lazy sprite: -> Spriter "images/tiles.png"

  life: 4.0
  hit: false
  color: { 255, 255, 255 }
  consumed: false

  ox: 0
  oy: 0

  new: (...) =>
    super ...
    @color = colors[@type]
    @rot = 0
    @dr = random_normal! - 0.5

  draw: =>
    @sprite\draw @cell, @x, @y, @rot, 1, 1, @ox, @oy
    -- b = Box 0, 0, 3, 3
    -- b\move_center(@x, @y)
    -- b\draw @color

  update: (dt, ...) =>
    super dt, ...
    @rot += @dr
    not @consumed

  send_to_mouth: (stage) =>
    @color = {255, 100, 255 }
    @hit = true
    @dr = (random_normal! - 0.5) * 2

    mouth = Vec2d stage.head.mouth_hitbox\center!
    @vel = (mouth - Vec2d(@x, @y))\normalized! * 200
    @accel = Vec2d(0, 100)

  consume: (stage) =>
    { :head } = stage
    return if head.puking

    @consumed = true
    if head.hungry_for[@type]
      head\eat @, stage
    else
      head\puke!

class SteakItem extends FoodItem
  ox: 10, oy: 10
  cell: "9,100,21,19"

  type: "steak"

class PastaItem extends FoodItem
  ox: 11, oy: 11
  cell: "49,100,22,22"

  type: "pasta"

class SodaItem extends FoodItem
  ox: 9, oy: 9
  cell: "91,102,18,18"
  type: "soda"

class FoodPile extends Box
  lazy sprite: -> Spriter "images/tiles.png"
  key: "X"

  color: {100, 100, 100}

  w: 20
  h: 20

  throw_gravity: Vec2d(0, 300)
  throw_dir: Vec2d(20, -100) * 2
  throw_speed: 200

  item_cls: FoodItem

  throw: (stage) =>
    cls = @item_cls

    if @inventory[@item] > 0
      x,y = @center!
      stage.particles\add cls x,y, @throw_dir * @throw_speed, @throw_gravity
      @inventory[@item] -= 1
    else
      print "ERROR NO #{@item} left"

  update: (dt) =>
    true

  draw_back: =>
    @sprite\draw "10,180,34,40", @x - 7, @y - 7
    p @key, @x + 7, @y - 10

  draw: =>
    @sprite\draw "50,180,26,20", @x - 3, @y
    @sprite\draw on_sprites[@item], @x + 5, @y + 5
    -- Box.outline @, @color

  new: (state) =>
    @inventory = state.game.inventory

class SteakPile extends FoodPile
  item_cls: SteakItem
  key: "1"

  item: "steak"
  color: colors.steak
  throw_dir: Vec2d 0.193022, -0.981194
  x: 9, y: 90

class PastaPile extends FoodPile
  item_cls: PastaItem
  key: "2"

  item: "pasta"
  color: colors.pasta
  throw_speed: 220
  throw_dir: Vec2d -0.090536, -0.995893
  x: 40, y: 105

class SodaPile extends FoodPile
  item_cls: SodaItem
  key: "3"

  item: "soda"
  color: colors.soda
  throw_speed: 240
  throw_dir: Vec2d -0.160396, -0.987053
  x: 70, y: 115

class FeedStage extends Stage
  name: "Feed Stage"
  lazy bg: -> imgfy "images/feed_bg.png"

  on_key: (key) =>
    pile_num = tonumber key

    if pile = @food_piles[pile_num]
      @player\goto_pile pile, @

    if key == " "
      @bat\swing @

  new: (...) =>
    super ...
    @head = Head!
    @particles = DrawList!
    @player = Player!
    @bat = Bat!

    @food_piles = {
      SteakPile @
      PastaPile @
      SodaPile @
    }

    with @entities
      \add @head
      \add_all @food_piles

      \add BoxSelector @game.viewport
      -- \add VectorSelector @game.viewport

      \add @player
      \add @bat

    sfx\play_music "stage2"

  make_hud: =>
    FeedHud @

  draw: =>
    @bg\draw 0,0

    for e in *@entities
      if e.draw_back
        e\draw_back!

    super!
    @hud\draw!
    @particles\draw!


  update: (dt) =>
    super dt
    -- see if particles hit anything
    for p in *@particles
      continue unless p.alive
      {:x, :y} = p

      if p.hit
        if @head.mouth_hitbox\touches_pt x, y
          p\consume @
      else
        if @bat.swinging and @bat\touches_pt x, y
          p\send_to_mouth @

    @particles\update dt, @



{ :Head, :Bat, :FeedHud, :Player, :FoodItem, :FoodPile, :FeedStage }
