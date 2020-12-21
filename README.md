# Dotenv for Elixir [![Hex pm](http://img.shields.io/hexpm/v/dotenv.svg?style=flat)](https://hex.pm/packages/dotenv) ![.github/workflows/main.yaml](https://github.com/iloveitaly/dotenv_elixir/workflows/.github/workflows/main.yaml/badge.svg)


This is a port of @bkeepers' [dotenv](https://github.com/bkeepers/dotenv) project to Elixir. You can read more about dotenv on that project's page. The short version is that it simplifies developing projects where configuration is stored in environment variables (e.g. projects intended to be deployed to Heroku).

## WARNING: Not compatible with Elixir releases

Elixir has an excellent configuration system and this dotenv implementation has
a serious limitation in that it isn't available at compile time. It fits very
poorly into a deployment setup using Elixir releases, distillery, or similar.

Configuration management should be built around Elixir's existing configuration system. A good example is [Phoenix](http://www.phoenixframework.org/) which generates a
project where the production config imports the "secrets" from a file stored
outside of version control. Even if you're using this for development, the same
approach could be taken.

However, if you are using Heroku, Dokku, or another deployment process that does *not* use releases, read on!

### Quick Start

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

#### Using Environment Variables in Configuration

[Mix loads configuration before loading any application code.](https://github.com/elixir-lang/elixir/blob/52141f2a3fa69906397017883242948dd93d91b5/lib/mix/lib/mix/tasks/run.ex#L123) If you want to use `.env` variables in your application configuration, you'll need to load dotenv manually on application start and reload your application config:

```elixir
defmodule App.Application do
  use Application

  def start(_type, _args) do
    unless Mix.env == :prod do
      Dotenv.load
      Mix.Task.run("loadconfig")
    end

    # ... the rest of your application startup
  end
end
```

#### Elixir 1.9 and older

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

#### Reloading the `.env` file

The `Dotenv.reload!/0` function will reload the variables defined in the `.env` file.

More examples of the server API usage can be found in [dotenv_app_test.exs](https://github.com/avdi/dotenv_elixir/blob/master/test/dotenv_app_test.exs).

### Serverless API

If you would like finer-grained control over when variables are loaded, or would like to inspect them, Dotenv also provides a serverless API for interacting with `.env` files.

The `load!/1` function loads variables into the process environment, and can be passed a path or list of paths to read from.

Alternately, `load/1` will return a data structure of the variables read from the `.env` file:

```elixir
iex(1)> Dotenv.load
%Dotenv.Env{paths: ["/elixir/dotenv_elixir/.env"],
 values: %{"APP_TEST_VAR" => "HELLO"}}
```

For further details, see the inline documentation. Usage examples can be found in [dotenv_test.exs](https://github.com/avdi/dotenv_elixir/blob/master/test/dotenv_test.exs).
