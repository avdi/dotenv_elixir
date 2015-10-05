defmodule Dotenv.Env do
  @type t :: %Dotenv.Env{paths: [String.t], values: %{String.t => String.t}}
  defstruct paths: [], values: HashDict.new

  def path(%Dotenv.Env{paths: paths}) do
    Enum.join(paths, ":")
  end

  def get(env, key) do
    Dotenv.Env.get(env, System.get_env(key), key)
  end

  def get(%Dotenv.Env{values: values}, fallback, key) when is_function(fallback) do
    HashDict.get(values, key, fallback.(key))
  end

  def get(%Dotenv.Env{values: values}, fallback, key) do
    HashDict.get(values, key, fallback)
  end
end
