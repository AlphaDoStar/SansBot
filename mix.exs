defmodule SansBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :sans_bot,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SansBot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:iris_ex, git: "https://github.com/AlphaDoStar/IrisEx.git"}
    ]
  end
end
