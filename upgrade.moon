{graphics: g, :timer} = love

export ^


class UpgradeSlot
  current_level: 0
  max_level: 4
  line_height: 18

  on_color: { 200, 80,80 }
  off_color: { 80,80,80 }

  new: (@key, @name, @current_level) =>

  update: (dt) =>
    true

  draw: (x,y) =>
    old_font = g.getFont!
    g.setFont fonts.tall

    g.push!
    g.translate x, y
    p "(#{@key})  #{@name}", 0,0

    g.translate 0, 12
    for i=1, @max_level
      COLOR\push i <= @current_level and @on_color or @off_color
      g.rectangle "fill", 0, 0, 10, 3
      COLOR\pop!
      g.translate 12, 0

    g.pop!
    g.setFont old_font

class UpgradeStage extends Stage
  lazy bg: -> imgfy "images/upgrade_bg.png"

  name: "Upgrade Stage"
  money_earned: 0

  new: (...) =>
    super ...

    u = (name) ->
      key = name\sub 1, 1
      UpgradeSlot key, name, @game.upgrades[name]

    @buy_upgrades = {
      u "sneakers"
      u "bartering"
      u "guts"
    }

    @feed_upgrades = {
      u "rollerskates"
      u "laxitives"
      u "fiber"
      u "organization"
    }

    satisfation = 1.0


    @health = HorizBar 110, 6, satisfation
    @health.tween_speed = 0.15
    @health.value = 0

    @emitter = Sequence ->
      if @health.display_value > 0
        x = @health.display_value * @health.w + 40
        y = 20

        earned = 11

        @game.inventory.money += earned
        @money_earned += earned

        @particles\add MoneyEmitter\make_particle x, y
        wait 0.1
        again!

    with @entities
      \add @emitter
      \add BoxSelector @game.viewport

    sfx\play_music "stage3"

  on_key: (key) =>
    return if @upgraded

    for upgrade in all_values @buy_upgrades, @feed_upgrades
      if upgrade.key == key and upgrade.current_level < upgrade.max_level
        @upgraded = true
        upgrade.current_level += 1
        @game.upgrades[upgrade.name] += 1

  draw: =>
    t = timer.getTime!

    @bg\draw 0,0

    super!

    g.push!
    g.translate 8, 20
    p "Satis.", 0, 0
    @health\draw 38, 0

    COLOR\push 207, 246, 208
    p "+$#{@money_earned}", @health.w + 36 + 4, 0
    COLOR\pop!

    g.pop!

    if math.floor(t*2) % 3 > 0
      p "Choose An Upgrade - Press Key", 12, 120

    g.push!
    g.translate 10, 35

    for i, u in ipairs @buy_upgrades
      u\draw 0, (i - 1) * UpgradeSlot.line_height

    g.pop!

    g.push!
    g.translate 100, 35

    for i, u in ipairs @feed_upgrades
      u\draw 0, (i - 1) * UpgradeSlot.line_height

    g.pop!
    @hud\draw!

  update: (dt, ...) =>
    super dt, ...
    @health\update dt


{ :UpgradeStage, :UpgradeSlot }
