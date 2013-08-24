require "lovekit.all"

{graphics: g} = love

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
  }

  g.setFont fonts.number_font

  export dispatch = Dispatcher Game!

  -- dispatch.update = (dt) =>
  --   Dispatcher.update @, dt * 4

  dispatch\bind love

