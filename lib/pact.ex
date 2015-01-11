defmodule Pact do
  @moduledoc """
  A module for managing dependencies in your application. You can set, get, and
  override dependencies globally or per-pid.

  ## Example

  ```
  Pact.start
  Pact.put(:http, HTTPoison)

  Pact.get(:http).get("https://google.com")

  # You can also override per module

  Pact.override(self, :http, FakeHTTP)

  spawn(fn ->
    Pact.get(:http).get("https://google.com") # Calls HTTPoison
  end)

  Pact.get(:http).get("https://google.com") # Calls FakeHTTP
  ```
  """

  use GenServer

  def start(initial_modules\\ %{}) do
    modules = %{modules: initial_modules, overrides: %{}, stubs: %{}}
    GenServer.start(__MODULE__, modules, name: __MODULE__)
  end

  @doc "Gets the dependency with `name`"
  def get(name) do
    name = to_string(name)
    GenServer.call(__MODULE__, {:get, name})
  end

  @doc "Assign `module` to the key `name`"
  def put(name, module) do
    name = to_string(name)
    GenServer.cast(__MODULE__, {:put, name, module})
  end

  @doc "Override all calls to `name` in `pid` with `module`"
  def override(pid, name, module) do
    name = to_string(name)
    GenServer.cast(__MODULE__, {:override, pid, name, module})
  end

  @doc "Remove override from process"
  def remove_override(pid, name) do
    name = to_string(name)
    GenServer.cast(__MODULE__, {:remove_override, pid, name})
  end

  @doc "Stop Pact"
  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  # GenServer

  def init(container) do
    {:ok, container}
  end

  def handle_cast({:put, name, module}, container) do
    modules = container.modules
              |> Map.put(name, module)

    {:noreply, %{container | modules: modules}}
  end

  def handle_cast({:override, pid, name, module}, container) do
    override = Map.get(container.overrides, pid, %{})
               |> Map.put(name, module)

    overrides = Map.put(container.overrides, pid, override)

    {:noreply, %{container | overrides: overrides}}
  end

  def handle_cast({:remove_override, pid, name}, container) do
    override = Map.get(container.overrides, pid, %{})
               |> Map.delete(name)

    if Map.size(override) == 0 do
      overrides = Map.delete(container.overrides, pid)
    else
      overrides = Map.put(container.overrides, pid, override)
    end

    {:noreply, %{container | overrides: overrides}}
  end

  def handle_call({:get, name}, {pid, _ref}, container) do
    override = deep_get(container.overrides, [pid, name])

    if override do
      module = override
    else
      module = Map.get(container.modules, name)
    end

    {:reply, module, container}
  end

  def handle_call(:stop, _from, container) do
    {:stop, :normal, :ok, container}
  end

  defp deep_get(object, path) do
    value = Enum.reduce(path, object, fn (part, map) ->
      Map.get(map, part, %{})
    end)

    if value == %{} do
      nil
    else
      value
    end
  end
end
