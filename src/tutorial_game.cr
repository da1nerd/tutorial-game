require "prism"
require "./game"

# This is a demonstration of building a game with `Prism`.
module TutorialGame
  VERSION = "0.1.0"
end

Prism::Context.run("Prism Tutorial Game", TutorialGame::Game.new)
