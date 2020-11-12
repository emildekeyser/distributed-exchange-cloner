defmodule ClonerTest do
  use ExUnit.Case
  doctest Cloner

  test "greets the world" do
    assert Cloner.hello() == :world
  end
end
