defmodule Dotenv do
  import Enum
  use Application.Behaviour

  # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
  # for more information on OTP Applications
  def start(_type, env_path // :automatic) do
    Dotenv.Supervisor.start_link(env_path)
  end

  @pattern %r/^\s*(\w+)\s*[:=]\s*(\S+)\s*$/m

  defrecord Env, paths: [], values: [] do
    def path(env) do
      join(env.paths, ":")
    end

    def get(key, env) do
      Dict.get(env.values, key, nil)
    end

    def get(key, fallback, env) when is_function(fallback) do
      Dict.get(env.values, key, fallback.(key))
    end

    def get(key, fallback, env) do
      Dict.get(env.values, key, fallback)
    end
  end

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

  def get(key, fallback // nil) do
    :gen_server.call :dotenv, {:get, key, fallback}
  end

  ##############################################################################
  # Serverless API
  ##############################################################################

  def load!(env_path // :automatic) do
    env = load(env_path)
    System.put_env(env.values)
    env
  end

  def load(env_path // :automatic)

  def load([env_path|env_paths]) do
    first_env = load(env_path)
    rest_env  = load(env_paths)
    Env[paths:  [env_path|rest_env.paths],
        values: Dict.merge(first_env.values, rest_env.values)]
  end

  def load([]) do
    Env[paths: [], values: []]
  end

  def load(env_path) do
    import Enum
    {env_path, contents} = read_env_file(env_path)
    matches = Regex.scan(@pattern, contents)
    values  = reduce(matches, [], fn([_whole, key, value], env) ->
                                     Dict.merge(env, [{key, value}])
                                 end)
    Env[paths: [env_path], values: values]
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

defimpl Access, for: Dotenv.Env do
  def access(env, key) do
    env.get(key,System.get_env(key))
  end
end