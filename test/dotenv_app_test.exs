defmodule DotenvAppTest do
  use ExUnit.Case

  def fixture_dir, do: Path.expand("../fixture", __ENV__.file())
  def proj1_dir, do: Path.join(fixture_dir(), "proj1")
  def root_dir, do: Path.expand("../..", __ENV__.file())

  setup do
    Dotenv.reload!(Path.join(root_dir(), ".env"))

    on_exit(fn ->
      System.put_env("APP_TEST_VAR", "")
      System.put_env("FOO_BAR", "")
      System.put_env("MISSING", "")
    end)
  end

  test "reloading from a new file" do
    Dotenv.reload!(Path.join(proj1_dir(), ".env"))
    assert Dotenv.get("FOO_BAR") == "1234"
    assert System.get_env("FOO_BAR") == "1234"
  end

  test "fetching the whole environment" do
    env = Dotenv.env()

    # no need to expand
    assert Map.get(env.values, "APP_TEST_VAR") == "HELLO"

    # expand

    assert Map.get(env.values, "EXPAND_VALUE_1") == "HELLO"
    assert Map.get(env.values, "EXPAND_VALUE_2") == "TEST_HELLO"
    assert Map.get(env.values, "EXPAND_VALUE_3") == "TEST_"
    assert Map.get(env.values, "EXPAND_VALUE_4") == "TEST_HELLO_TEST"
    assert Map.get(env.values, "EXPAND_VALUE_5") == "TEST_HELLO_TEST"
    assert Map.get(env.values, "EXPAND_VALUE_6") == "TEST_HELLO_TEST_HELLO"
    assert Map.get(env.values, "EXPAND_VALUE_7") == "TEST_HELLO_TEST_"

    # no expand
    assert Map.get(env.values, "SKIP_EXPAND_VALUE_REPLACE_1") == "TEST_\\$APP_TEST_VAR"
    assert Map.get(env.values, "SKIP_EXPAND_VALUE_REPLACE_2") == "TEST_\\${APP_TEST_VAR}"
    assert Map.get(env.values, "SKIP_EXPAND_VALUE_REPLACE_3") == "TEST_\\${APP_TEST_VAR}_TEST"
    assert Map.get(env.values, "SKIP_EXPAND_VALUE_REPLACE_4") == "TEST_\\${APP_TEST_VAR}_TEST"
  end

  test "getting a value with a fallback" do
    assert Dotenv.get("APP_TEST_VAR", :fallback) == "HELLO"
    assert Dotenv.get("MISSING", :fallback) == :fallback
    assert Dotenv.get("MISSING", fn _ -> :generated_fallback end) == :generated_fallback
  end

  test "fetching a var" do
    assert Dotenv.get("APP_TEST_VAR") == "HELLO"
    assert System.get_env("APP_TEST_VAR") == "HELLO"
  end

  test "should fallback expanded" do
    assert Dotenv.get("EXPAND_VALUE_6") == "TEST_HELLO_TEST_HELLO"
    assert Dotenv.get("SKIP_EXPAND_VALUE_REPLACE_1") == "TEST_\\$APP_TEST_VAR"

    assert System.get_env("EXPAND_VALUE_6") == "TEST_HELLO_TEST_HELLO"
    assert System.get_env("SKIP_EXPAND_VALUE_REPLACE_1") == "TEST_\\$APP_TEST_VAR"
  end
end
