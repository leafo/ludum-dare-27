require "lovekit.all"

{graphics: g} = love

class Game
  new: =>
    @viewport = Viewport scale: 2

  update: (dt) =>

  draw: =>
    @viewport\apply!
    g.print "Hello world", 10, 10
    @viewport\pop!

love.load = ->
  export dispatch = Dispatcher Game!
  dispatch\bind love

