defmodule Pact.Mixfile do
  use Mix.Project

  def project do
    [app: :pact,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps,
     description: description,
     source_url: "https://github.com/BlakeWilliams/pact",
     package: package
   ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.6", only: :dev},
      {:meck, "~> 0.8.2"}
    ]
  end

  defp description do
    "Better dependency injection in Elixir through inversion of control"
  end

  defp package do
    %{contributors: ["Blake Williams"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/BlakeWilliams/pact"}}
  end
end
