require "lovekit.all"

{graphics: g} = love

class Timer
  time: 10

  new: (@x, @y) =>

  draw: =>
    old_font = g.getFont!
    g.setFont fonts.number_font
    g.print tostring(@), @x, @y

    g.setFont old_font

  update: (dt) =>
    @time -= dt
    @reset! if @time < 0
    true

  reset: =>
    @time = 10

  __tostring: =>
    "0:%02d"\format math.ceil(@time)

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

class Game
  new: =>
    @viewport = Viewport scale: 2
    @player = Player 100, 100

    t = Timer 10, 10

    @entities = DrawList!
    @entities\add @player
    @entities\add t

  collides: =>
    false

  update: (dt) =>
    @entities\update dt, @

  draw: =>
    @viewport\apply!
    @entities\draw!
    @viewport\pop!

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  export fonts = {
    number_font: load_font "images/number_font.png", [[0123456789:]]
  }

  g.setFont fonts.number_font

  export dispatch = Dispatcher Game!
  dispatch\bind love

