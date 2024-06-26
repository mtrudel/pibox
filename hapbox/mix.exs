defmodule HAPBox.MixProject do
  use Mix.Project

  def project do
    [
      app: :hapbox,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [mod: {HAPBox.Application, []}, extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hap, "~> 0.5"},
      {:circuits_i2c, "~> 1.0.1"}
    ]
  end
end
