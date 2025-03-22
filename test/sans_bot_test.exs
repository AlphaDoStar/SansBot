defmodule SansBotTest do
  use ExUnit.Case
  doctest SansBot

  test "greets the world" do
    assert SansBot.hello() == :world
  end
end
