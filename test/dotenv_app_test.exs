defmodule DotenvAppTest do
  use ExUnit.Case

  def fixture_dir, do: Path.expand("../fixture", __FILE__)
  def proj1_dir, do: Path.join(fixture_dir, "proj1")

  setup do
    Dotenv.reload!
  end

  test "fetching a var" do
    assert Dotenv.get("APP_TEST_VAR") == "HELLO"
    assert System.get_env("APP_TEST_VAR") == "HELLO"
  end

  test "reloading from a new file" do
    Dotenv.reload!(Path.join(proj1_dir, ".env"))
    assert Dotenv.get("FOO_BAR") == "1234"
    assert System.get_env("FOO_BAR") == "1234"
  end

  test "fetching the whole environment" do
    env = Dotenv.env
    assert Dict.get(env.values, "APP_TEST_VAR") == "HELLO"
  end

  test "getting a value with a fallback" do
    assert Dotenv.get("APP_TEST_VAR", :fallback) == "HELLO"
    assert Dotenv.get("MISSING", :fallback) == :fallback
  end
end