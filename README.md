# Dotenv for Elixir

This is a port of @bkeepers' [dotenv](https://github.com/bkeepers/dotenv) project to Elixir. You can read more about [dotenv](https://github.com/bkeepers/dotenv) on that project's page. The short version is that it simplifies developing projects where configuration is stored in environment variables (e.g. projects intended to be deployed to Heroku).

There is a simple local API which can be used to either load the environment into a data structure, or modify the process environment. Until more documentation exists, please see [dotenv_test.exs](https://github.com/avdi/dotenv_elixir/blob/master/test/dotenv_test.exs) for usage.

There is also a rudimentary server, if you prefer. See [dotenv_app_test.exs](https://github.com/avdi/dotenv_elixir/blob/master/test/dotenv_app_test.exs) for usage.
