defmodule FakeApp.Pact do
  use Pact

  register "http", HTTPoison
end

defmodule PactTest do
  use ExUnit.Case, async: true

  setup_all do
    FakeApp.Pact.start_link
    :ok
  end

  test "accesses pre-registered modules" do
    assert FakeApp.Pact.get("http") === HTTPoison
  end

  test "registers and accesses modules manually" do
    FakeApp.Pact.register("markdown", Earmark)

    assert FakeApp.Pact.get("markdown") ==  Earmark
  end

  test "replaces modules only in block" do
    require FakeApp.Pact

    FakeApp.Pact.replace "http", FakeHTTP do
      assert FakeApp.Pact.get("http") == FakeHTTP
    end

    assert FakeApp.Pact.get("http") == HTTPoison
  end

  test "generates anonymous modules to use with replace" do
    require FakeApp.Pact

    fakeHTTP = FakeApp.Pact.generate :HTTPoison do
      def get(url) do
        url
      end
    end

    assert fakeHTTP.get("url") == "url"
  end

  test "generates fake and replace module only in block" do
    require FakeApp.Pact

    fakeHTTP = FakeApp.Pact.generate :HTTPoison, do: nil

    FakeApp.Pact.replace "http", fakeHTTP do
      assert FakeApp.Pact.get("http") == fakeHTTP
    end
  end

  test "replacing dependencies on process for async testing" do
    require FakeApp.Pact

    fakeHTTP = FakeApp.Pact.generate :HTTPoison do
      def get(url), do: url
    end

    otherFakeHTTP = FakeApp.Pact.generate :HTTPoison do
      def get(url), do: "#{url}/alternate"
    end

    1..10000
      |> Enum.map(fn indx ->
        [
          Task.async(fn  -> replace(fakeHTTP, indx, indx) end),
          Task.async(fn  -> replace(otherFakeHTTP, indx, "#{indx}/alternate") end)
        ]
      end)
      |> Enum.each(fn [task1, task2] ->
        Process.monitor(task1.pid)
        Process.monitor(task2.pid)
      end)
  end

  defp replace(module, input, assertion) do
    require FakeApp.Pact

    FakeApp.Pact.replace "http", module, :process do
      assert FakeApp.Pact.get("http").get(input) == assertion
    end
  end

end
