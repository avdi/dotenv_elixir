# Dotenv for Elixir [![Hex pm](http://img.shields.io/hexpm/v/dotenv.svg?style=flat)](https://hex.pm/packages/dotenv) ![.github/workflows/main.yaml](https://github.com/iloveitaly/dotenv_elixir/workflows/.github/workflows/main.yaml/badge.svg)

This is a port of @bkeepers' [dotenv](https://github.com/bkeepers/dotenv) project to Elixir. You can read more about dotenv on that project's page. The short version is that it simplifies developing projects where configuration is stored in environment variables (e.g. projects intended to be deployed to Heroku).

See the [dotenv documentation on hexdocs](https://hexdocs.pm/dotenv/api-reference.html) for more info.

## Quick Start

The simplest way to use Dotenv is with the included OTP application. This will automatically load variables from a `.env` file in the root of your project directory into the process environment when started.

First add `dotenv` to your dependencies.

For the latest release:

```elixir
{:dotenv, "~> 3.0.0"}
```

Most likely, if you are deploying in a Heroku-like environment, you'll want to only load the package in a non-production environment:

```elixir
{:dotenv, "~> 3.0.0", only: [:dev, :test]}
```

For master:

```elixir
{:dotenv, github: "avdi/dotenv_elixir"}
```

Fetch your dependencies with `mix deps.get`.

Now, when you load your app in a console with `iex -S mix`, your environment variables will be set automatically.

## Elixir 1.9 and older

If you are running an old version of Elixir, you'll need to add the `:dotenv` application to your applications list when running in the `:dev` environment:

```elixir
# Configuration for the OTP application
def application do
  [
    mod: { YourApp, [] },
    applications: app_list(Mix.env)
  ]
end

defp app_list(:dev), do: [:dotenv | app_list]
defp app_list(_), do: app_list
defp app_list, do: [...]
```
