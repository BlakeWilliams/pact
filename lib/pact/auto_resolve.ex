defmodule Pact.AutoResolve do

  defmacro __using__(_) do
    quote do
      require Annotatable
      use Annotatable, [:resolve]
      @before_compile Pact.AutoResolve
    end
  end

  defmacro __before_compile__(env) do
    annotations = Module.get_attribute(env.module, :annotations)
    annotations |> Enum.map(fn {name, [%{method_info: method_info, value: value}]} ->
      {args, _, _} = method_info
      [dependencies | no_dep_args] = Enum.reverse args
      no_dep_args =  Enum.reverse no_dep_args
      dependency_keys = dependencies |> Enum.map(fn {name, _} -> name end)

      quote do
        def unquote(:"#{name}")(unquote_splicing(no_dep_args)) do
          deps = unquote(dependency_keys) |> Enum.map(fn key ->
            {key, unquote(value).get(key)}
          end)
          deps = unquote(no_dep_args) ++ [deps]
          apply(__MODULE__, unquote(name), deps)
        end
      end

    end)
  end

end
