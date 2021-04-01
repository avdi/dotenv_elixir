defmodule Dotenv.Env do
  @moduledoc """
  This struct stores the values gleaned from the `.env` files located at
  the given paths.  Accessor functions are provided.
  """
  @type t :: %Dotenv.Env{paths: [String.t()], values: %{String.t() => String.t()}}
  defstruct paths: [], values: Map.new()

  @doc """
  Reveals the path(s) used to populate the given `%Dotenv.Env{}`, returned as
  a string.

  ## Examples

      iex> Dotenv.env() |> Dotenv.Env.path()
      "automatic"
  """
  def path(%Dotenv.Env{paths: paths}) do
    Enum.join(paths, ":")
  end

  @doc """
  Gets the value at the given `key` from the given `%Dotenv.Env{}`.
  If the `key` is not defined in the `env` provided, `nil` is returned.
  """
  @spec get(env :: Dotenv.Env.t(), String.t()) :: any()
  def get(env, key) do
    Dotenv.Env.get(env, System.get_env(key), key)
  end

  @doc """
  Gets the value at the given `key` from the given `%Dotenv.Env{}`.
  If the `key` is not defined in the `env` provided, the `fallback` will be
  returned as a default value if the `fallback` is not a function.
  If the `fallback` value is a function, it will only be evaluated if the
  `key` is not present in the given `env`.

  ## Examples

      iex> env = Dotenv.env()
      iex> Dotenv.Env.get(env, "default-value", "KEY_DOES_NOT_EXIST")
      "default-value"
  """
  def get(%Dotenv.Env{values: values}, fallback, key) when is_function(fallback) do
    Map.get(values, key, fallback.(key))
  end

  def get(%Dotenv.Env{values: values}, fallback, key) do
    Map.get(values, key, fallback)
  end
end
