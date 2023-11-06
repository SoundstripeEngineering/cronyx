defmodule Cronyx.MixProject do
  use Mix.Project

  def project do
    [
      app: :cronyx,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ssl, :ecto, :ecto_sql, :postgrex],
      mod: {Cronyx.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poolboy, "~> 1.5"},
      {:ecto_sql, "~> 3.8"},
      {:postgrex, "~> 0.17.3"},
      {:ex_doc, "~> 0.30.6", only: :dev, runtime: false}
    ]
  end
end
