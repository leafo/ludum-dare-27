{graphics: g} = love

export ^


class UpgradeSlot
  current_level: 0
  max_level: 4

  on_color: { 200, 80,80 }
  off_color: { 80,80,80 }

  new: (@key, @name, @current_level) =>

  update: (dt) =>
    true

  draw: (x,y) =>
    g.push!
    g.translate x, y
    p "|#{@key}|: #{@name}", 0,0

    g.translate 0, 8
    for i=1, @max_level
      COLOR\push i <= @current_level and @on_color or @off_color
      g.rectangle "fill", 0,0, 10, 3
      COLOR\pop!
      g.translate 12, 0

    g.pop!

class UpgradeState extends Stage
  name: "Upgrade Stage"

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

  on_key: (key) =>
    return if @upgraded

    for upgrade in all_values @buy_upgrades, @feed_upgrades
      if upgrade.key == key and upgrade.current_level < upgrade.max_level
        @upgraded = true
        upgrade.current_level += 1
        @game.upgrades[upgrade.name] += 1

  draw: =>
    super!

    p "Choose An Upgrade (Press Key)", 20, 25

    g.push!
    g.translate 8, 40

    for i, u in ipairs @buy_upgrades
      u\draw 0, (i - 1) * 15

    g.pop!

    g.push!
    g.translate 95, 40

    for i, u in ipairs @feed_upgrades
      u\draw 0, (i - 1) * 15

    g.pop!

