defmodule Upyun.Mixfile do
  use Mix.Project

  @description """
  A community version of Upyun SDK, released by Helijia.com.
  """

  def project do
    [
      app: :hlj_upyun,
      version: "0.1.1",
      elixir: ">= 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: @description,
      package: package()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :httpoison, :mime]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:httpoison, "~> 0.9.0"},
      {:poison, "~> 2.2"},
      {:mime, "~> 1.0"},
      {:credo, ">= 0.0.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:inch_ex, ">= 0.0.0", only: :docs}
    ]
  end


  defp package do
    [
      maintainers: ["qhwa"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/qhwa/elixir-upyun"}
    ]
  end
end
