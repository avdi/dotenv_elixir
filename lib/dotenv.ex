defmodule Dotenv do
  @moduledoc """
  This module implements both an OTP application API and a "serverless" API.

  Server API
  ==========

  Start the application with `start/2` On starting, it will automatically export
  the environment variables in the default path (`.env`).

  The environment can then be reloaded with `reload!/0` or a specific path
  or list of paths can be provided to `reload!/1`.

  Serverless API
  ==============

  To use the serverless API, you can either load the environment variables with
  `load!` (again, optionally passing in a path or list of paths), or you
  can retrieve the variables without exporting them using `load`.
  """

  use Application
  alias Dotenv.Env

  def start(_type, env_path \\ :automatic) do
    Dotenv.Supervisor.start_link(env_path)
  end

  @pattern ~r/^\s*(\w+)\s*[:=]\s*(\S+)\s*$/m

  ##############################################################################
  # Server API
  ##############################################################################

  @doc """
  Calls the server to reload the values in the `.env` file into the
  system environment.

  This call is asynchronous (`cast`).
  """
  @spec reload!() :: :ok
  def reload! do
    :gen_server.cast :dotenv, :reload!
  end

  @doc """
  Calls the server to reload the values in the file located at `env_path` into
  the system environment.

  This call is asynchronous (`cast`).
  """
  @spec reload!(any) :: :ok
  def reload!(env_path) do
    :gen_server.cast :dotenv, {:reload!, env_path}
  end

  @doc """
  Returns the current state of the server as a `Dotenv.Env` struct.
  """
  @spec env() :: Env.t
  def env do
    :gen_server.call :dotenv, :env
  end

  @doc """
  Retrieves the value of the given `key` from the server, or `fallback` if the
  value is not found.
  """
  @spec get(String.t, String.t) :: String.t
  def get(key, fallback \\ nil) do
    :gen_server.call :dotenv, {:get, key, fallback}
  end

  ##############################################################################
  # Serverless API
  ##############################################################################

  @doc """
  Reads the env files at the provided `env_path` path(s), exports the values into
  the system environment, and returns them in a `Dotenv.Env` struct.
  """
  def load!(env_path \\ :automatic) do
    env = load(env_path)
    System.put_env(env.values)
    env
  end

  @doc """
  Reads the env files at the provided `env_path` path(s) and returns the values in a `Dotenv.Env` struct.
  """
  @spec load([String.t]) :: Env.t
  @spec load(String.t) :: Env.t
  def load(env_path \\ :automatic)

  def load([env_path|env_paths]) do
    first_env = load(env_path)
    rest_env  = load(env_paths)
    %Env{paths:  [env_path|rest_env.paths],
         values: Dict.merge(first_env.values, rest_env.values)}
  end

  def load([]) do
    %Env{paths: [], values: HashDict.new}
  end

  def load(env_path) do
    {env_path, contents} = read_env_file(env_path)
    matches = Regex.scan(@pattern, contents)
    values  = Enum.reduce(matches, HashDict.new, fn([_whole, key, value], env) ->
                                                   HashDict.merge(env, HashDict.new |> HashDict.put(key, value))
                                                 end)
    %Env{paths: [env_path], values: values}
  end

  defp read_env_file(:automatic) do
    case find_env_path do
      {:ok, env_path} -> {env_path, File.read!(env_path)}
      {:error, _}     -> {:none, ""}
    end
  end

  defp read_env_file(:none) do
    {:none, ""}
  end

  defp read_env_file(env_path) do
    {env_path, File.read!(env_path)}
  end

  defp find_env_path do
    find_env_path(File.cwd!)
  end

  defp find_env_path(dir) do
    candidate = Path.join(dir, ".env")
    cond do
      File.exists?(candidate) -> {:ok, candidate}
      dir == "/"              -> {:error, "No .env found"}
      true                    -> find_env_path(Path.dirname(dir))
    end
  end
end
