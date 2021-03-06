require "lovekit.all"

{graphics: g, :keyboard} = love

export p = (str, ...) ->
  g.print str\lower!, ...

require "particles"
require "misc"
require "buy"
require "feed"
require "upgrade"
require "screens"

export ^

class Game
  paused: false

  new: =>
    @stage_i = 1
    @stages = {
      BuyStage
      FeedStage
      UpgradeStage
    }

    @inventory = {
      money: 60

      steak: 0
      pasta: 0
      soda: 0
    }

    @stats = {
      earned: 0
      rounds: 0
      fed: 0
    }

    @upgrades = {
      -- buy
      sneakers: 0 --
      bartering: 0 --
      guts: 0 --
      hair: 0 --

      -- feed
      rollerskates: 0 --
      laxatives: 0 --
      fiber: 0 --
      organization: 0
    }

    @sequence = Sequence ->
      @current_stage = @stages[@stage_i] @, @current_stage
      wait_until -> @current_stage.done
      @stage_i = (@stage_i % #@stages) + 1
      again!

    @viewport = Viewport scale: 4

  update: (dt) =>
    return if @paused
    -- dt = dt * 10 if keyboard.isDown "return"

    @sequence\update dt

    if @current_stage
      @current_stage\update dt

  on_key: (key, ...) =>
    if key == "escape"
      if @current_stage and not @current_stage.tutorial
        @current_stage.locked = true
        @current_stage.tutorial = GameOver @current_stage
      else
        dispatch\pop!

      return true

    if key == "p"
      @paused = not @paused

    -- if num = key\match "f(%d)"
    --   num = tonumber num
    --   if new = @stages[num]
    --     @current_stage = num
    --     @current_stage = new @
    --     return

    if @current_stage and @current_stage.on_key
      @current_stage\on_key key, ...

  draw: =>
    @viewport\apply!

    if @current_stage
      @current_stage\draw!
      @current_stage\draw_top!

    @viewport\pop!

    p tostring(love.timer.getFPS!), 8, 8

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  export fonts = {
    number_font: load_font "images/number_font.png", [[0123456789:]]
    default: load_font "images/font_thick.png", [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&/+]]
    tall: load_font "images/tall_font.png", [[abcdefghijklmnopqrstuvwxyz.() ]]
  }

  export sfx = lovekit.audio.Audio "sounds"
  -- sfx.play_music = ->
  sfx\preload {
    "bat_hit"
    "eat_food"
    "hit"
    "ok"
    "puke"
    "purchase"
    "step"
    "throw"
    "error"
    "swing"
    "get_money"
  }

  g.setFont fonts.default
  -- export dispatch = Dispatcher Game!
  export dispatch = Dispatcher TitleScreen!

  -- dispatch.update = (dt) =>
  --   Dispatcher.update @, dt * 4

  dispatch\bind love

