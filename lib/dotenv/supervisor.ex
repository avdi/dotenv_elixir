defmodule Dotenv.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(env_path \\ :automatic) do
    :supervisor.start_link(__MODULE__, env_path)
  end

  def init(env_path) do
    children = [worker(Dotenv.Server, env_path)]

    # See http://elixir-lang.org/docs/stable/Supervisor.Behaviour.html
    # for other strategies and supported options
    supervise(children, strategy: :one_for_one)
  end
end
