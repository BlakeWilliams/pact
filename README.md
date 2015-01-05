# Pact

Better dependency injection in Elixir for cleaner code and testing.

## Why?

Because testing Elixir flat out sucks. Why clutter up your code injecting
dependencies when a process can handle it for you?

* You can declare your modules instead of passing them around like state.
* You can override dependencies per process to make testing easier.
* It makes your code look a lot cleaner.

## Usage

```elixir
Pact.start
Pact.put("string", String)

Pact.get("string").to_atom("xyz") # => :xyz

Pact.override(self, "string", Integer)
Pact.get("string").parse("1234") # => {1234, ""}
```

## Disclaimer

Pact is very much an experiment at this point to see if it's viable. If you use
Pact please get in touch with me to let me know how it worked out for you or how
you think it could improve. If you have ideas feel free to open an issue or
create a pull request.
