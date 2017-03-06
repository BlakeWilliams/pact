defmodule Foo do
  def bar(argument), do: "foo:#{argument}"
end

defmodule ResolvedFakeApp.Pact do
  use Pact

  register :foo, Foo
end

defmodule ResolvedFakeApp.AutoResolve do
  use Pact.AutoResolve

  @resolve ResolvedFakeApp.Pact
  def resolve(arg, [foo: foo]) do
     foo.bar(arg)
  end
end

defmodule AutoResolveTest do
  use ExUnit.Case, async: true

  setup_all do
    ResolvedFakeApp.Pact.start_link
    :ok
  end

  test "automatically resolve pact dependencies" do
    require ResolvedFakeApp.Pact
    assert ResolvedFakeApp.AutoResolve.resolve("arg") == "foo:arg"
  end

end
