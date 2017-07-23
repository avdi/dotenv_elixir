defmodule DotenvElixir.Mixfile do
  use Mix.Project

  def project do
    [ app: :dotenv,
      version: "3.0.0",
      elixir: "~> 1.0",
      deps: deps(),
      package: [
        maintainers: ["Jared Norman"],
        contributors: ["Avdi Grimm", "David Rouchy", "Jared Norman", "Louis Simoneau"],
        links: %{github: "https://github.com/avdi/dotenv_elixir"},
        licenses: ["MIT"]
      ],
      description: """
      A port of dotenv to Elixir
      """ ]
  end

  # Configuration for the OTP application
  def application do
    [mod: { Dotenv, [:automatic] }]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, git: "https://github.com/elixir-lang/foobar.git", tag: "0.1" }
  #
  # To specify particular versions, regardless of the tag, do:
  # { :barbat, "~> 0.1", github: "elixir-lang/barbat.git" }
  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev}]
  end
end
