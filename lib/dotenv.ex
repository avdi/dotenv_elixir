defmodule Dotenv do
  @moduledoc """
  This is a port of @bkeepers' [dotenv](https://github.com/bkeepers/dotenv)
  project to Elixir.  It supports comments and variable substitutions.

  ## Background

  Because Elixir is a compiled language with runtime flexibility, configuration
  can be more confusing than you might be used to.  With the release of Elixir
  1.11 and its `runtime.exs` configuration file, it is now easier to follow the
  methodology of the [12 Factor App](https://12factor.net/) and its
  recommendation to store configuration details in the environment (for example,
  in `.env` files).  This is especially important when `mix release` is used to
  build executable artifacts that must run _without_ `Mix`.  Instead of making
  one app, you can easily end up with _three_ mostly-but-not-exactly-identical
  applications (for `dev`, `prod`, and `test` environments).  Besides the
  problem of having untestable code (because in such a scenario, some code may
  not exist in the `test` environment) it is a bewildering state of affairs!

  This package can help organize your configuration and make it easier to keep
  configuration details in the environment.

  ## Loading Config

  There are two primary ways that configuration values can be loaded:

  `load/1` parses variables and their values from one or more files and returns
  them in a `%Dotenv.Env{}` struct.

  `load!/1` performs the same parsing as `load/1`, but it includes a side effect
  of putting these values into the environment via `System.put_env/1`


      iex(1)> Dotenv.load()
      %Dotenv.Env{paths: ["path/to/.env"], values: %{"APP_TEST_VAR" => "HELLO"}}

  ## Usage Suggestion

  In order to be compatible both with regular `mix` execution of your app and
  with mix releases, a proper solution needs to load configuration _before_
  your application starts.  As mentioned previously, some things in Elixir must
  be configured at compile-time (e.g. modules with macros), but a lot of your
  application can be configured at runtime.

  Imagine a simple `.env` at the root of your application:

      DB_URL=postgres://myuser:mypassw0rd@localhost/mydb

  If you wish to hard-code configuration values in your `config/test.exs`, then
  your `config/runtime.exs` can rely on the `Config.config_env/0` function to
  load your `.env` file(s) only when running in other configuration environments
  (e.g. `dev` or `prod`).

      # runtime.exs
      import Config

      if config_env() != :test do
        Dotenv.load!(".env")

        config :yourapp,
          db_url: System.fetch_env!("DB_URL"),
          # ... etc ...
      end

  Alternatively, you may wish to define a dedicated configuration file for each
  environment (e.g. `.env.test`, etc.), in which case, you `runtime.exs` might
  look like this:

      import Config
      Dotenv.load!(".env.\#{config_env()}")

      config :yourapp,
          db_url: System.fetch_env!("DB_URL"),
          # ... etc ...


  For further examples, see the usage examples in
  [dotenv_test.exs](https://github.com/avdi/dotenv_elixir/blob/master/test/dotenv_test.exs).
  """

  use Application
  alias Dotenv.Env

  def start(_type, env_path \\ :automatic) do
    Dotenv.Supervisor.start_link(env_path)
  end

  @quotes_pattern ~r/^(['"])(.*)\1$/
  @pattern ~r/
    \A
    (?:export\s+)?    # optional export
    ([\w\.]+)         # key
    (?:\s*=\s*|:\s+?) # separator
    (                 # optional value begin
      '(?:\'|[^'])*?' #   single quoted value
      |               #   or
      "(?:\"|[^"])*?" #   double quoted value
      |               #   or
      [^#\n]+?        #   unquoted value
    )?                # value end
    (?:\s*\#.*)?      # optional comment
    \z
    /x

  # https://regex101.com/r/XrvCwE/1
  @env_expand_pattern ~r/
    (?:^|[^\\])                           # prevent to expand \\$
    (                                     # get variable key pattern
      \$                                  #
      (?:                                 #
        ([A-Z0-9_]*[A-Z_]+[A-Z0-9_]*)     # get variable key
        |                                 #
        (?:                               #
          {([A-Z0-9_]*[A-Z_]+[A-Z0-9_]*)} # get variable key between {}
        )                                 #
      )                                   #
    )                                     #
    /x

  ##############################################################################
  # Server API
  ##############################################################################

  @doc """
  Reloads the values from `.env` file into the
  system environment.

  This call is asynchronous (`cast`).
  """
  @spec reload!() :: :ok
  def reload! do
    :gen_server.cast(:dotenv, :reload!)
  end

  @doc """
  Calls the server to reload the values in the file located at `env_path` into
  the system environment.

  This call is asynchronous (`cast`).
  """
  @spec reload!(env_path :: any()) :: :ok
  def reload!(env_path) do
    :gen_server.cast(:dotenv, {:reload!, env_path})
  end

  @doc """
  Returns the current state of the server as a `Dotenv.Env` struct.
  The server will have read the file at the path provided at start.

  ## Examples

      iex> Dotenv.env()
      %Dotenv.Env{
        paths: [:automatic],
        values: %{
          "FOO" => "sample-value",
          "BAR" => "123"
        }
      }
  """
  @spec env() :: Env.t()
  def env do
    :gen_server.call(:dotenv, :env)
  end

  @doc """
  Retrieves the value of the given `key` from the server state, or `default` if the
  value is not found.

  ## Examples

      iex> Dotenv.get("SOME_VAR_THAT_IS_SET")
      "some-value"
      iex> Dotenv.get("DOES_NOT_EXIST")
      nil
      iex> Dotenv.get("DOES_NOT_EXIST", 123)
      123
  """
  @spec get(String.t(), String.t() | nil) :: String.t()
  def get(key, default \\ nil) do
    :gen_server.call(:dotenv, {:get, key, default})
  end

  ##############################################################################
  # Serverless API
  ##############################################################################

  @doc """
  Reads the env files at the provided `env_path` path(s), exports the values into
  the system environment, and returns them in a `Dotenv.Env` struct.
  This will overwrite values in the system environment: subsequent calls to
  `System.get_env/2` will be affected.
  If the path is omitted, `:automatic` is assumed.

  If you do not wish to overwrite system variables, use `load/1` instead.

  ## Examples

      iex> Dotenv.load!("path/to/.env.example")
      %Dotenv.Env{
        paths: ["path/to/.env.example"],
        values: %{"FOO_BAR" => "PROJ2_FOO_BAR", "PROJ2_VAR" => "9876"}
      }
  """
  def load!(env_path \\ :automatic) do
    env = load(env_path)
    System.put_env(env.values)
    env
  end

  @doc """
  Reads the env file at the provided `env_path` path(s) and returns the values in
  a single `Dotenv.Env` struct.  A single file or a list of files may be provided.
  If a path is omitted, `:automatic` discovery is used.

  ## Examples

      iex> Dotenv.load(["path1/.env", "path2/.env"])
      %Dotenv.Env{
        paths: ["path1/.env", "path2/.env"],
        values: %{
          "A" => "apple",
          "B" => "beta"
        }
      }

  """
  @spec load(String.t() | :automatic | [String.t()]) :: Env.t()
  def load(env_path \\ :automatic)

  def load([env_path | env_paths]) do
    first_env = load(env_path)
    rest_env = load(env_paths)

    %Env{paths: [env_path | rest_env.paths], values: Map.merge(first_env.values, rest_env.values)}
  end

  def load([]) do
    %Env{paths: [], values: Map.new()}
  end

  def load(env_path) do
    {env_path, contents} = read_env_file(env_path)
    values = contents |> parse_contents()
    %Env{paths: [env_path], values: values}
  end

  @doc """
  This parses the string contents of a file with "dotenv" formatting and returns
  the values as a map.  Variable values may be referenced after they are declared
  by using the `${VAR_NAME}` syntax.

  ## Sample Syntax

  Here is a sample `.env` file:

      NAME=Bob
      GREETING="Hello ${NAME}"
      DO_NOT_EXPAND="Hello \\${NAME}"

  ## Examples

      iex> contents = File.read!(".env")
      iex(16)> Dotenv.parse_contents(contents)
      %{
        "NAME" => "Bob",
        "GREETING" => "Hello Bob"
      }
  """
  @spec parse_contents(contents :: String.t()) :: map()
  def parse_contents(contents) do
    values = String.split(contents, "\n")

    values
    |> Enum.flat_map(&Regex.scan(@pattern, &1))
    |> trim_quotes_from_values
    |> Enum.reduce([], &expand_env/2)
    |> Enum.reduce(Map.new(), &collect_into_map/2)
  end

  defp collect_into_map([_whole, k, v], env), do: Map.put(env, k, v)
  defp collect_into_map([_whole, _k], env), do: env

  defp trim_quotes_from_values(values) do
    values
    |> Enum.map(fn values ->
      Enum.map(values, &trim_quotes/1)
    end)
  end

  defp trim_quotes(value) do
    String.replace(value, @quotes_pattern, "\\2")
  end

  # without value
  defp expand_env([_whole, _k], acc), do: acc

  defp expand_env([whole, k, v], acc) do
    matchs = Regex.scan(@env_expand_pattern, v)

    new_value =
      case Enum.empty?(matchs) do
        true ->
          v

        false ->
          matchs
          |> Enum.reduce(v, fn [_whole, pattern | keys], v ->
            v |> replace_env(pattern, keys, acc)
          end)
      end

    acc ++ [[whole, k, new_value]]
  end

  defp replace_env(value, pattern, ["" | keys], env), do: replace_env(value, pattern, keys, env)
  defp replace_env(value, pattern, [key | _], env), do: replace_env(value, pattern, key, env)

  defp replace_env(value, pattern, key, %Env{} = env) do
    new_value = env |> Env.get(key) || ""

    pattern
    |> Regex.escape()
    |> Regex.compile!()
    |> Regex.replace(value, new_value)
  end

  defp replace_env(value, pattern, key, acc) when is_list(acc) do
    values = acc |> Enum.reduce(Map.new(), &collect_into_map/2)
    replace_env(value, pattern, key, %Env{values: values})
  end

  defp replace_env(value, pattern, key, %{} = values) do
    replace_env(value, pattern, key, %Env{values: values})
  end

  defp read_env_file(:automatic) do
    case find_env_path() do
      {:ok, env_path} -> {env_path, File.read!(env_path)}
      {:error, _} -> {:none, ""}
    end
  end

  defp read_env_file(:none) do
    {:none, ""}
  end

  defp read_env_file(env_path) do
    {env_path, File.read!(env_path)}
  end

  defp find_env_path do
    find_env_path(File.cwd!())
  end

  defp find_env_path(dir) do
    candidate = Path.join(dir, ".env")

    cond do
      File.exists?(candidate) -> {:ok, candidate}
      dir == "/" -> {:error, "No .env found"}
      true -> find_env_path(Path.dirname(dir))
    end
  end
end
