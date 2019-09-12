defmodule MetaLoggerTest do
  use ExUnit.Case
  doctest MetaLogger

  test "greets the world" do
    assert MetaLogger.hello() == :world
  end
end
