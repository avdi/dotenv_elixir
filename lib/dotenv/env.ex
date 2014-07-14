defmodule Dotenv.Env do
  defstruct paths: [], values: HashDict.new

  def path(%Dotenv.Env{paths: paths}) do
    Enum.join(paths, ":")
  end

  def get(%Dotenv.Env{values: values}, key) do
    HashDict.get(values, key, nil)
  end

  def get(%Dotenv.Env{values: values}, fallback, key) when is_function(fallback) do
    HashDict.get(values, key, fallback.(key))
  end

  def get(%Dotenv.Env{values: values}, fallback, key) do
    HashDict.get(values, key, fallback)
  end
end

defimpl Access, for: Dotenv.Env do
  def get(env, key) do
    Dotenv.Env.get(env, System.get_env(key), key)
  end

  def get_and_update(env, _key, _fun), do: env
end
