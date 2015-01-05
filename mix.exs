defmodule Pact.Mixfile do
  use Mix.Project

  def project do
    [app: :pact,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps,
     licenses: "MIT",
     contributors: "Blake Williams",
     description: description,
     links: links
   ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end

  defp description do
    "Better dependency injection in Elixir through inversion of control"
  end

  defp links do
    [%{github: "https://github.com/BlakeWilliams"}]
  end
end
