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

  @doc """
    Replace the given `name` for `pid` with the given expression. This will
    generate a new module with the given methods.

    ## Example

    ```
    import Pact

    Pact.put(:enum, Enum)
    Pact.replace self, :enum do
      def map(_map, _fn) do
        [1, 2, 3]
      end
    end
    ```

    So now if you call `Pact.get(:enum).map(%{}, fn -> end)` it will return
    `[1, 2, 3]`.
  """
  defmacro replace(pid, name, expression) do
    body = Keyword.get(expression, :do)
    uid = :base64.encode(:crypto.strong_rand_bytes(5))
    module_name = Module.concat([Pact, Fakes, name, uid])
    module = Module.create(module_name, body, Macro.Env.location(__ENV__))

    quote do
      Pact.override(unquote(pid), unquote(name), unquote(module_name))
    end
  end

  def start(initial_modules\\ %{}) do
    modules = %{modules: initial_modules, overrides: %{}}
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
    modules =
      container.modules
      |> Map.put(name, module)

    {:noreply, %{container | modules: modules}}
  end

  def handle_cast({:override, pid, name, module}, container) do
    override =
      Map.get(container.overrides, pid, %{})
      |> Map.put(name, module)

    overrides = Map.put(container.overrides, pid, override)

    {:noreply, %{container | overrides: overrides}}
  end

  def handle_cast({:remove_override, pid, name}, container) do
    override =
      Map.get(container.overrides, pid, %{})
      |> Map.delete(name)

    if Map.size(override) == 0 do
      overrides = Map.delete(container.overrides, pid)
    else
      overrides = Map.put(container.overrides, pid, override)
    end

    {:noreply, %{container | overrides: overrides}}
  end

  def handle_call({:get, name}, {pid, _ref}, container) do
    override = get_in(container.overrides, [pid, name])

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
end
