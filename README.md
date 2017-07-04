# WARNING: This isn't the Elixir way.

Elixir has an excellent configuration system and this dotenv implementation has
a serious limitation in that it isn't available at compile time. It fits very
poorly into a typical deployment setup using exrm or similar. Configuration
management should be built around Elixir's existing not system, not environment
variables.

A good example is [Phoenix](http://www.phoenixframework.org/) which generates a
project where the production config imports the "secrets" from a file stored
outside of version control. Even if you're using this for development, the same
approach could be taken.

If you're sure this is the correct solution to a problem in your
development/deployment workflow, read on!

## Dotenv for Elixir

This is a port of @bkeepers' [dotenv](https://github.com/bkeepers/dotenv) project to Elixir. You can read more about [dotenv](https://github.com/bkeepers/dotenv) on that project's page. The short version is that it simplifies developing projects where configuration is stored in environment variables (e.g. projects intended to be deployed to Heroku).

### Quick Start

The simplest way to use Dotenv is with the included OTP application. This will automatically load variables from a `.env` file in the root of your project directory into the process environment when started.

First add `dotenv` to your dependencies.

For the latest release:

```elixir
{:dotenv, "~> 2.0.0"}
```

For master:

```elixir
{:dotenv, github: "avdi/dotenv_elixir"}
```

Fetch your dependencies with `mix deps.get`.

Now, add the `:dotenv` application to your applications list when running in the `:dev` environment:

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

Now, when you load your app in a console with `iex -S mix`, your environment variables will be set automatically.

#### Reloading the `.env` file

The `Dotenv.reload!/0` function will reload the variables defined in the `.env` file.

More examples of the server API usage can be found in [dotenv_app_test.exs](https://github.com/avdi/dotenv_elixir/blob/master/test/dotenv_app_test.exs).

### Serverless API

If you would like finer-grained control over when variables are loaded, or would like to inspect them, Dotenv also provides a serverless API for interacting with `.env` files.

The `load!/1` function loads variables into the process environment, and can be passed a path or list of paths to read from.

Alternately, `load/1` will return a data structure of the variables read from the `.env` file:

```
iex(1)> Dotenv.load
%Dotenv.Env{paths: ["/elixir/dotenv_elixir/.env"],
 values: %{"APP_TEST_VAR" => "HELLO"}}
```

For further details, see the inline documentation. Usage examples can be found in [dotenv_test.exs](https://github.com/avdi/dotenv_elixir/blob/master/test/dotenv_test.exs).
