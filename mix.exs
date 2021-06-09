defmodule DotenvElixir.Mixfile do
  use Mix.Project

  @source_url "https://github.com/avdi/dotenv_elixir"
  @version "3.1.0"

  def project do
    [
      app: :dotenv,
      version: @version,
      elixir: "~> 1.0",
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  # Configuration for the OTP application
  def application do
    [
      mod: {Dotenv, [:automatic]}
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp package do
    [
      description: "A port of dotenv to Elixir",
      maintainers: ["Jared Norman"],
      contributors: [
        "Avdi Grimm",
        "David Rouchy",
        "Jared Norman",
        "Louis Simoneau",
        "Michael Bianco"
      ],
      licenses: ["MIT"],
      links: %{
        GitHub: @source_url
      }
    ]
  end
end
