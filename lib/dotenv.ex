defmodule Dotenv do
  use Application
  alias Dotenv.Env

  def start(_type, env_path \\ :automatic) do
    Dotenv.Supervisor.start_link(env_path)
  end

  @pattern ~r/^\s*(\w+)\s*[:=]\s*(\S+)\s*$/m

  ##############################################################################
  # Server API
  ##############################################################################

  def reload! do
    :gen_server.cast :dotenv, :reload!
  end

  def reload!(env_path) do
    :gen_server.cast :dotenv, {:reload!, env_path}
  end

  def env do
    :gen_server.call :dotenv, :env
  end

  def get(key, fallback \\ nil) do
    :gen_server.call :dotenv, {:get, key, fallback}
  end

  ##############################################################################
  # Serverless API
  ##############################################################################

  def load!(env_path \\ :automatic) do
    env = load(env_path)
    System.put_env(env.values)
    env
  end

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

  def read_env_file(:automatic) do
    case find_env_path do
      {:ok, env_path} -> {env_path, File.read!(env_path)}
      {:error, _}     -> {:none, ""}
    end
  end

  def read_env_file(:none) do
    {:none, ""}
  end

  def read_env_file(env_path) do
    {env_path, File.read!(env_path)}
  end

  def find_env_path do
    find_env_path(File.cwd!)
  end

  def find_env_path(dir) do
    candidate = Path.join(dir, ".env")
    cond do
      File.exists?(candidate) -> {:ok, candidate}
      dir == "/"              -> {:error, "No .env found"}
      true                    -> find_env_path(Path.dirname(dir))
    end
  end
end
