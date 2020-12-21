defmodule DotenvTest do
  use ExUnit.Case, async: true

  def fixture_dir, do: Path.expand("../fixture", __ENV__.file())
  def proj1_dir, do: Path.join(fixture_dir(), "proj1")
  def proj2_dir, do: Path.join(fixture_dir(), "proj2")
  def proj3_dir, do: Path.join(fixture_dir(), "proj3")

  test "parsing a simple dotenv file" do
    File.cd! proj1_dir()
    env = Dotenv.load
    assert Dotenv.Env.path(env) == Path.expand(".env", proj1_dir())
    assert Dotenv.Env.get(env, "FOO_BAR") == "1234"
    assert Dotenv.Env.get(env, "BAZ") == "5678"
    assert Dotenv.Env.get(env, "BUZ") == "9999"
    assert Dotenv.Env.get(env, "QUX") == "0000"
  end

  test "parsing a simple dotenv file as found in the real world" do
    File.cd! proj3_dir()
    env = Dotenv.load
    assert Dotenv.Env.get(env, "EMPTY") == nil
    assert Dotenv.Env.path(env) == Path.expand(".env", proj3_dir())
    assert Dotenv.Env.get(env, "EXTERNAL_HOST") == "external.example.com"
    assert Dotenv.Env.get(env, "EXTERNAL_PROTOCOL") == "https"
    assert Dotenv.Env.get(env, "INTERNAL_HOST") == "internal.example.com"
    assert Dotenv.Env.get(env, "INTERNAL_PROTOCOL") == "https"
  end

  test "it parses values in double quotes" do
    File.cd! proj1_dir()
    env = Dotenv.load
    assert Dotenv.Env.get(env, "DOUBLE_QUOTED_VALUE") == "NoDoubleQuotes"
  end

  test "it parses values in single quotes" do
    File.cd! proj1_dir()
    env = Dotenv.load
    assert Dotenv.Env.get(env, "SINGLE_QUOTED_VALUE") == "NoSingleQuotes"
  end

  test "finding the dotenv from a subdir" do
    File.cd! Path.join(proj1_dir(), "subdir")
    env = Dotenv.load
    assert Dotenv.Env.path(env) == Path.expand(".env", proj1_dir())
    assert Dotenv.Env.get(env, "FOO_BAR") == "1234"
    assert Dotenv.Env.get(env, "BAZ") == "5678"
    assert Dotenv.Env.get(env, "BUZ") == "9999"
    assert Dotenv.Env.get(env, "QUX") == "0000"
  end

  test "loading into system environment" do
    import System, only: [get_env: 1]
    File.cd!(Path.join(proj1_dir(), "subdir"))
    Dotenv.load!
    assert get_env("FOO_BAR") == "1234"
    assert get_env("BAZ")     == "5678"
    assert get_env("BUZ")     == "9999"
    assert get_env("QUX")     == "0000"
  end

  test "falling back to system environment" do
    File.cd! proj1_dir()
    System.put_env "FOO_BAR", "ORIGINAL_FOO_BAR"
    System.put_env "BAZZLE", "4321"
    env = Dotenv.load
    assert Dotenv.Env.path(env) == Path.expand(".env", proj1_dir())
    # .env values take precedence
    assert Dotenv.Env.get(env, "FOO_BAR") == "1234"
    assert Dotenv.Env.get(env, "BAZZLE") == "4321"
  end

  test "with explicit file" do
    env_path = Path.join(proj2_dir(), ".env")
    env = Dotenv.load!(env_path)
    assert Dotenv.Env.path(env) == env_path
    assert System.get_env("PROJ2_VAR") == "9876"
  end

  test "with multiple explicit files" do
    env_paths = [Path.join(proj1_dir(), ".env"), Path.join(proj2_dir(), ".env")]
    env = Dotenv.load!(env_paths)
    assert Dotenv.Env.path(env) == env_paths |> Enum.join(":")
    assert System.get_env("PROJ2_VAR") == "9876"
    assert System.get_env("FOO_BAR") == "PROJ2_FOO_BAR"
  end
end
