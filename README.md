# ElixirUpyun

Upyun client for Elixir.

warning: This is an unofficial and under development SDK. APIs may change frequently. Do NOT use it in your production.

## Installation

The package can be installed as:

  1. Add `upyun` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:upyun, github: "qhwa/elixir-upyun"}]
    end
    ```

  2. Ensure `upyun` is started before your application:

    ```elixir
    def application do
      [applications: [:upyun]]
    end
    ```

