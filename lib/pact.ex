defmodule Pact do
  use GenServer

  def start(initial_modules\\ %{}) do
    modules = %{modules: initial_modules, overrides: %{}}
    GenServer.start(__MODULE__, modules, name: __MODULE__)
  end

  def get(name) do
    name = to_atom(name)
    GenServer.call(__MODULE__, {:get, name})
  end

  def put(name, module) do
    name = to_atom(name)
    GenServer.cast(__MODULE__, {:put, name, module})
  end

  def override(pid, name, module) do
    name = to_atom(name)
    GenServer.cast(__MODULE__, {:override, pid, name, module})
  end

  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  # GenServer

  def init(container) do
    {:ok, container}
  end

  def handle_cast({:put, name, module}, container) do
    modules = container.modules
    modules = Map.put(modules, name, module)

    {:noreply, %{container | modules: modules}}
  end

  def handle_cast({:override, pid, name, module}, container) do
    override = Map.get(container.overrides, pid, %{})
                |> Map.put(name, module)

    overrides = Map.put(container.overrides, pid, override)

    {:noreply, %{container | overrides: overrides}}
  end

  def handle_call({:get, name}, {pid, _ref}, container) do
    override = Map.get(container.overrides, pid, %{})[name]
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

  def to_atom(val) do
    val |> to_string |> String.to_atom
  end
end
