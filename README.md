# Datadog Distillery Plugin

[![Master](https://travis-ci.org/Homepolish/datadog_distillery_plugin.svg?branch=master)](https://travis-ci.org/Homepolish/datadog_distillery_plugin)

This plugin is used with the [Gigalixir Datadog Buildpack](https://github.com/Homepolish/gigalixir-buildpack-datadog).
Please refer to that library for integration with Datadog and the Gigalixir platform.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `datadog_distillery_plugin` to your list of dependencies in `mix.exs`:

> Requires Elixir 1.7 or greater. It works with Erlang 20+.

```elixir
def deps do
  [
    {:datadog_distillery_plugin, "~> 0.1.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/datadog_distillery_plugin](https://hexdocs.pm/datadog_distillery_plugin).

## Usage

In your Distillery config (`rel/config.exs`), add the following:

```elixir
environment :prod do
  plugin(Mix.Releases.DatadogPlugin)
  ...
end
```
