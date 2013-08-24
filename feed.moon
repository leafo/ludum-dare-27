{graphics: g} = love

export ^

class FeedStage extends Stage
  new: =>
    super!

  draw: =>
    @timer\draw!
    p "Feed Stage", 100, 10

  update: (dt) =>
    @timer\update dt
