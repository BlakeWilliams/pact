defmodule PactTest do
  use ExUnit.Case

  setup do
    Pact.start
    :ok
  end

  test "it can assign and use modules", _context do
    Pact.put("string", String)

    assert Pact.get("string").to_atom("xyz") == :xyz
  end

  test "it can re-assign modules" do
    Pact.put("string", String)
    Pact.put("string", Integer)

    assert Pact.get("string") == Integer
  end

  test "it can override specific processes" do
    self_pid = self

    Pact.put("string", String)
    Pact.override(self_pid, "string", Integer)

    spawn fn -> 
      send self_pid, {:module, Pact.get("string")}
    end

    assert Pact.get("string") == Integer
    assert_receive {:module, Elixir.String}
  end

  test "it can access and set by atom and string" do
    Pact.put("string", String)
    assert Pact.get(:string) == String

    Pact.put(:string, Integer)
    assert Pact.get("string") == Integer
  end
end
