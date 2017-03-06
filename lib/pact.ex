defmodule Pact do
  @moduledoc """
  A module for managing dependecies in your applicaiton without having to
  "inject" dependencies all the way down your aplication. Pact allows you to
  set and get dependencies in your application code, and generate fakes and
  replace modules in your tests.

  To use Pact, define a module in your application that has `use Pact` in it,
  and then call `start_link` on it to start registering your dependencies.

  ## Usage

  ```
  defmodule MyApp.Pact do
    use Pact

    register "http", HTTPoison
  end

  MyApp.Pact.start_link

  defmodule MyApp.Users do
    def all do
      MyApp.Pact.get("http").get("http://foobar.com/api/users")
    end
  end
  ```

  Then in your tests you can use Pact to replace the module easily:

  ```
  defmodule MyAppTest do
    use ExUnit.Case
    require MyApp.Pact

    test "requests the corrent endpoint" do
      fakeHTTP = MyApp.Pact.generate :http do
        def get(url) do
          send self(), {:called, url}
        end
      end

      MyApp.Pact.replace "http", fakeHTTP do
        MyApp.Users.all
      end

      assert_receive {:called, "http://foobar.com/api/users"}
    end
  end
  ```

  ## Functions / Macros

  * `generate(name, block)` - Generates an anonymous module that's body is
    block`.
  * `replace(name, module, block)` - Replaces `name` with `module` in the given
    `block` only.
  * `register(name, module)` - Registers `name` as `module`.
  * `get(name)` - Get registed module for `name`.
  """

  defmacro __using__(_) do
    quote do
      import Pact
      use GenServer

      @modules %{}
      @before_compile Pact

      defmacro generate(name, do: block) do
        string_name = to_string(name)
        uid = :base64.encode(:crypto.strong_rand_bytes(5))

        module_name = String.to_atom("#{__MODULE__}.Fakes.#{string_name}.#{uid}")
        module = Module.create(module_name, block, Macro.Env.location(__ENV__))

        quote do
          unquote(module_name)
        end
      end


      defmacro replace(name, module, where \\ :registry, do: block) do
        quote do
          existing_module = unquote(__MODULE__).get(unquote(name))
          unquote(__MODULE__).register(unquote(name), unquote(module), unquote(where))
          unquote(block)
          unquote(__MODULE__).register(unquote(name), existing_module, unquote(where))
        end
      end

      def register(name, module), do: register(name, module, :registry)
      def register(name, module, :process), do: Process.put(name, module)
      def register(name, module, where ), do: GenServer.cast(__MODULE__, {:register, name, module})


      def get(name), do: Process.get(name, get(name, :registry))
      def get(name, :registry), do: GenServer.call(__MODULE__, {:get, name})

      # Genserver implementation

      def init(container) do
        {:ok, container}
      end

      def handle_cast({:register, name, module}, state) do
        modules = Map.put(state.modules, name, module)
        {:noreply, %{state | modules: modules}}
      end

      def handle_call({:get, name}, _from, state) do
        module = get_in(state, [:modules, name])
        {:reply, module, state}
      end
    end
  end

  @doc false
  defmacro register(name, module) do
    quote do
      @modules Map.put(@modules, unquote(name), unquote(module))
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def start_link do
        GenServer.start_link(__MODULE__, %{modules: @modules}, name: __MODULE__)
      end
    end
  end
end
