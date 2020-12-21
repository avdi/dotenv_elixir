defmodule Dotenv.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(env_path \\ :automatic) do
    Supervisor.start_link(__MODULE__, env_path)
  end

  def init(env_path) do
    children = [Supervisor.child_spec({Dotenv.Server, env_path}, [])]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
