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


class FoodPile extends Box
  color: {100, 100, 100}
  w: 20
  h: 20

  update: (dt) =>
    true

  draw: => super @color

class SteakPile extends FoodPile
  color: { 250, 92, 102 }
  x: 9, y: 90

class PastaPile extends FoodPile
  color: { 235, 199, 0 }
  x: 40, y: 105

class SodaPile extends FoodPile
  color: { 141, 74, 232 }
  x: 70, y: 115


class FeedStage extends Stage
  name: "Feed Stage"

  new: (...) =>
    super ...

    @food_piles = {
      SteakPile!
      PastaPile!
      SodaPile!
    }

    with @entities
      \add Head!
      \add_all @food_piles

      \add BoxSelector @game.viewport

