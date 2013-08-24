{graphics: g} = love

colors = {
  steak: { 250, 92, 102 }
  pasta: { 235, 199, 0 }
  soda: { 141, 74, 232 }
  gray: { 80,80,80 }
}

class FeedHud extends Hud
  -- box<(113, 2), (83, 12)>

  new: (...) =>
    super ...
    @satisfied = HorizBar 80, 6

  draw: =>
    super!
    hungry_for = @stage.head.hungry_for

    p "Satisfaction", 110, 1
    @satisfied\draw 110, 10

    p "Feed: ", 110, 20
    w = 5
    for i, food in ipairs {"steak", "pasta", "soda"}
      if hungry_for[food]
        COLOR\push colors[food]
      else
        COLOR\push colors.gray

      g.rectangle "fill",
        145 + (i - 1) * (w + 4), 21,
        w, w

      COLOR\pop!


class Player extends Box
  speed: 100

  w: 8
  h: 10

  x: 20
  y: 124

  goto_pile: (pile, stage) =>
    if pile == @current_pile
      pile\throw stage if not @seq
      return

    x,y = pile\center!
    @seq = Sequence ->
      @current_pile = pile
      len = Vec2d(x - @x, y - @y)\len!
      tween @, len / @speed, { :x, :y } -- , lerp
      pile\throw stage
      @seq = nil

  draw: =>
    super {100,255,100}

  update: (dt) =>
    if @seq
      @seq\update dt

    true

export ^

class Head extends Box
  -- box<(104, 76), (69, 39)>
  color: { 252, 231, 178 }
  mouth_color: { 255, 80, 80, 100 }
  puke_color: { 71, 128, 78 }

  x: 100
  y: 50

  w: 90
  h: 70

  new: =>
    super
    @mouth = Box 104, 76, 70, 40
    @mouth_hitbox = Box 104, 103, 70, 13

    @hungry_for = {
      steak: true
      pasta: true
      soda: true
    }

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
    super @color
    @mouth\draw @puking and @puke_color or @mouth_color

  update: (dt) =>
    @seq\update dt
    @puking\update dt if @puking
    true

  puke: =>
    @puking = Sequence ->
      print "I AM PUKING"
      wait 1.0
      @puking = nil

class Bat extends Box
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
    COLOR\push @color
    g.push!
    g.translate @wx, @wy
    g.rotate @rot
    g.rectangle "fill", @x, @y, @w, @h
    COLOR\pop!
    -- p "%.3f"\format(@rot), 0, 0
    -- p "%.3f"\format(@return_progress or 0), 0, 8
    g.pop!


class FoodItem extends Particle
  life: 4.0
  hit: false
  color: { 255, 255, 255 }
  consumed: false

  new: (...) =>
    super ...
    @color = colors[@type]

  draw: =>
    b = Box 0, 0, 3, 3
    b\move_center(@x, @y)
    b\draw @color

  update: (...) =>
    super ...
    not @consumed

  send_to_mouth: (stage) =>
    @color = {255, 100, 255 }
    @hit = true

    mouth = Vec2d stage.head.mouth\center!
    @vel = (mouth - Vec2d(@x, @y))\normalized! * 200
    @accel = Vec2d(0, 100)

  consume: (stage) =>
    { :head } = stage
    return if head.puking

    @consumed = true
    if head.hungry_for[@type]
      print "MMM"
    else
      head\puke!

class SteakItem extends FoodItem
  type: "steak"

class PastaItem extends FoodItem
  type: "pasta"

class SodaItem extends FoodItem
  type: "soda"

class FoodPile extends Box
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

  draw: => super @color

  new: (state) =>
    @inventory = state.game.inventory

class SteakPile extends FoodPile
  item_cls: SteakItem

  item: "steak"
  color: colors.steak
  throw_dir: Vec2d 0.193022, -0.981194
  x: 9, y: 90

class PastaPile extends FoodPile
  item_cls: PastaItem

  item: "pasta"
  color: colors.pasta
  throw_speed: 220
  throw_dir: Vec2d -0.090536, -0.995893
  x: 40, y: 105

class SodaPile extends FoodPile
  item_cls: SodaItem

  item: "soda"
  color: colors.soda
  throw_speed: 240
  throw_dir: Vec2d -0.160396, -0.987053
  x: 70, y: 115

class FeedStage extends Stage
  name: "Feed Stage"

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

  make_hud: =>
    FeedHud @

  draw: =>
    super!
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

