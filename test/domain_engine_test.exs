defmodule DomainEngineTest do
  use ExUnit.Case
  doctest DomainEngine

  test "greets the world" do
    assert DomainEngine.hello() == :world
  end
end
