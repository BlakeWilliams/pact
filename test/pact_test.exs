defmodule PactTest do
  use ExUnit.Case
  import Pact

  setup_all do
    Pact.start

    on_exit fn ->
      Pact.stop
    end
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

  test "replace module replaces the given module" do
    Pact.put("foo", String)

    Pact.replace self, "foo" do
      def awesome?, do: true
      def lame?, do: false
    end

    assert Pact.get("foo").awesome? == true
    assert Pact.get("foo").lame? == false
  end

  test "replace generates unique module names" do
    Pact.put("foo", String)

    Pact.replace self, "foo" do; end
    module = Pact.get("foo")

    Pact.replace self, "foo" do; end
    new_module = Pact.get("foo")

    assert to_string(module) != to_string(new_module)
  end
end
