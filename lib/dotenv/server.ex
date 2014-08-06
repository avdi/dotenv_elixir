defmodule Dotenv.Server do
  @moduledoc false
  use GenServer

  def start_link(env_path) do
    :gen_server.start_link({:local, :dotenv}, __MODULE__, env_path, [])
  end

  def init(env_path) do
    env = Dotenv.load!(env_path)
    {:ok, env}
  end

  def handle_cast(:reload!, env) do
    {:noreply, Dotenv.load!(env.paths)}
  end

  def handle_cast({:reload!, env_path}, _env) do
    {:noreply, Dotenv.load!(env_path)}
  end

  def handle_call(:env, _from, env) do
    {:reply, env, env}
  end

  def handle_call({:get, key, fallback}, _from, env) do
    {:reply, Dotenv.Env.get(env, fallback, key), env}
  end
end
