
{graphics: g, :timer} = love

class T extends FadeTransition
  time: 0.4

export ^

class TitleScreen
  lazy bg: -> imgfy "images/title_bg.png"
  lazy head_img: -> imgfy "images/title_head.png"

  new: =>
    @viewport = Viewport scale: 4
    @entities = DrawList!
    sfx\play_music "title"

    @entities\add RevealString "Press Enter", 24, 120, 0.2

  update: (dt) =>
    @entities\update dt

  on_key: (key) =>
    if key == "return"
      sfx\play "ok"
      dispatch\push Game!, T

  on_show: =>
    sfx\play_music "title"

  draw: =>
    @viewport\apply!

    @bg\draw 0,0
    @head_img\draw 110, 20 + math.cos(timer.getTime!) * 6

    old_font = g.getFont!
    g.setFont fonts.tall
    @entities\draw!
    g.setFont old_font

    @viewport\pop!


class BuyTutorial
  strs: {
    "Greetings!"
    ""
    "My boyfriend... He's starving!"
    ""
    "Take this $100 and buy him"
    "some food! Quickly!"
    ""
    "Arrow keys move,"
    "space to buy from vendors."
    ""
    "Press enter to begin"
  }

  new: (@parent) =>
    @viewport = Viewport scale: 4
    @entities = DrawList!

    @entities\add Sequence ->
      for i, str in ipairs @strs
        reveal = RevealString str, 10, i * 10, 0.05
        @entities\add reveal
        wait_until -> reveal.done

  update: (dt) =>
    @entities\update dt

  on_key: (key) =>
    if key == "return"
      @parent\remove_tutorial!

  draw: =>
    @parent.game.viewport\draw {0,0,0, 180}
    @entities\draw!

class FeedTutorial extends BuyTutorial
  strs: {
    "Great,"
    "I hope you got some food."
    ""
    "He's very large, you need to"
    "use a baseball bat to knock"
    "the food into his mouth!"
    ""
    "Throw food with keys 1,2,3"
    ""
    "Swing the bat in time with"
    "space. Watch for his appetite."
    ""
    "Press enter to begin"
  }

{ :TitleScreen, :TutorialScreen }
