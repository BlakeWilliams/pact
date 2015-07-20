defmodule Pact.Mixfile do
  use Mix.Project

  def project do
    [app: :pact,
     version: "0.2.0",
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
    ]
  end

  defp description do
    "Elixir dependency registry for better testing and cleaner code"
  end

  defp package do
    %{contributors: ["Blake Williams", "Paul Smith"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/BlakeWilliams/pact"}}
  end
end
