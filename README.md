# Pact

Pact is a dependency registry for Elixir to make testing dependencies easier.
## Why?

Because testing Elixir dependencies could be a lot better. Why clutter up your
code injecting dependencies when a process can handle it for you?

* You can declare your modules instead of passing them around like state.
* You can replace dependencies in a block context for easy testing.
* It makes your code cleaner.

## Usage

In your application code:

```elixir
defmodule MyApp.Pact do
  use Pact

  register "http", HTTPoison
end

MyApp.Pact.start_link

defmodule MyApp.Users do
  def all do
    MyApp.Pact.get("http").get!("http://foobar.com/api/users")
  end
end

```

In your tests:

```elixir
defmodule MyApp.UserTest do
  use ExUnit.Case
  require MyApp.Pact

  test "requests the corrent endpoint" do
    fakeHTTP = MyApp.Pact.generate :http do
      def get!(url) do
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

You can find more information in the [documentation].

[documentation]: http://hexdocs.pm/pact

## Disclaimer

Pact is very much an experiment at this point to see if it's viable. If you use
Pact please get in touch with me to let me know how it worked out for you or how
you think it could improve. If you have ideas feel free to open an issue or
create a pull request.
