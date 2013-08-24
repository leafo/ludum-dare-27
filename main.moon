require "lovekit.all"

{graphics: g} = love

export p = (str, ...) ->
  g.print str\lower!, ...

require "misc"
require "buy"
require "feed"

class Game
  new: =>
    @stage_i = 1
    @stages = {
      BuyStage
      FeedStage
    }

    @sequence = Sequence ->
      @current_stage = @stages[@stage_i]!
      wait_until -> @current_stage\is_done!
      @stage_i = (@stage_i % #@stages) + 1
      again!

    @viewport = Viewport scale: 4

  update: (dt) =>
    @sequence\update dt

    if @current_stage
      @current_stage\update dt

  draw: =>
    @viewport\apply!

    if @current_stage
      @current_stage\draw!

    @viewport\pop!

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  export fonts = {
    number_font: load_font "images/number_font.png", [[0123456789:]]
    default: load_font "images/font_thick.png", [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&/]]
  }

  g.setFont fonts.default
  export dispatch = Dispatcher Game!

  -- dispatch.update = (dt) =>
  --   Dispatcher.update @, dt * 4

  dispatch\bind love

