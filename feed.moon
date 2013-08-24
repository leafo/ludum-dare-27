{graphics: g} = love

export ^

class Head extends Box
  -- box<(104, 76), (69, 39)>
  color: { 252, 231, 178 }
  mouth_color: { 255, 80, 80, 100 }

  x: 100
  y: 50

  w: 90
  h: 70

  new: =>
    super
    @mouth = Box 104, 76, 70, 40

  draw: =>
    super @color
    @mouth\draw @mouth_color

  update: (dt) =>
    true


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


class Bat extends Box
  color: { 200, 188, 66 }

  ox: 8
  oy: 4


  x: 50
  y: 50

  w: 70
  h: 8

  rot: 0

  rest_rot: 2.7018146928204
  swing_rot: 1.7848146928204

  swing: =>
    if @return_progress and @return_progress > 0.8
      @seq = nil

    return if @seq

    @seq = Sequence ->
      @return_progress = 0
      tween @, 0.1, rot: @swing_rot
      tween @, 0.5, rot: @rest_rot, return_progress: 1
      @seq = nil

  update: (dt, stage) =>
    @rot = @rest_rot
    @seq\update dt if @seq
    true

  draw: =>
    COLOR\push @color
    g.push!
    g.translate @x, @y
    g.rotate @rot
    g.rectangle "fill", -@ox, -@oy, @w, @h
    COLOR\pop!
    -- p "%.3f"\format(@rot), 0, 0
    -- p "%.3f"\format(@return_progress or 0), 0, 8
    g.pop!


class FoodItem extends Particle
  life: 4.0

  draw: =>
    b = Box 0, 0, 3, 3
    b\move_center(@x, @y)
    b\draw { 255, 255, 255}

class FoodPile extends Box
  color: {100, 100, 100}

  w: 20
  h: 20

  throw_gravity: Vec2d(0, 300)
  throw_dir: Vec2d(20, -100) * 2
  throw_speed: 200

  throw: (stage) =>
    print "Throwing"
    x,y = @center!

    stage.particles\add FoodItem x,y, @throw_dir * @throw_speed, @throw_gravity

  update: (dt) =>
    true

  draw: => super @color

class SteakPile extends FoodPile
  color: { 250, 92, 102 }
  throw_dir: Vec2d 0.193022, -0.981194
  x: 9, y: 90

class PastaPile extends FoodPile
  color: { 235, 199, 0 }
  throw_speed: 220
  throw_dir: Vec2d -0.090536, -0.995893
  x: 40, y: 105

class SodaPile extends FoodPile
  color: { 141, 74, 232 }
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
    @particles = DrawList!
    @player = Player!
    @bat = Bat!

    @food_piles = {
      SteakPile!
      PastaPile!
      SodaPile!
    }

    with @entities
      \add Head!
      \add_all @food_piles

      -- \add BoxSelector @game.viewport
      -- \add VectorSelector @game.viewport
      \add @player
      \add @bat

  draw: =>
    super!
    @particles\draw!

  update: (dt) =>
    super dt
    @particles\update dt, @

