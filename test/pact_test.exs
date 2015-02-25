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

  test "creates a stubbed module with overridden functions for given process" do
    Pact.put("foo", String)
    self_pid = self

    Pact.override(self, "foo",
      trim: fn -> "bar" end,
      duplicate: fn(_string) -> "duplicated!" end
    )

    spawn fn ->
      send self_pid, {:module, Pact.get("foo")}
    end

    assert Pact.get("foo").trim == "bar"
    assert Pact.get("foo").duplicate("Stuff") == "duplicated!"
    assert_received {:module, String}
  end

  test "it can remove overrides" do
    Pact.put("string", String)
    Pact.override(self, "string", Integer)

    assert Pact.get("string") == Integer
    Pact.remove_override(self, "string")

    assert Pact.get("string") == String
  end

  test "it can access and set by atom and string" do
    Pact.put("string", String)
    assert Pact.get(:string) == String

    Pact.put(:string, Integer)
    assert Pact.get("string") == Integer
  end
end
