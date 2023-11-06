defmodule CronyxTest do
  use ExUnit.Case
  doctest Cronyx

  test "greets the world" do
    assert Cronyx.hello() == :world
  end
end
