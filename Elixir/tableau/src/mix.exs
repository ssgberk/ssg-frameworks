defmodule SSGBerk.MixProject do
  use Mix.Project

  def project do
    [
      app: :ssgberk,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: true,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:tableau, "== 0.30.0"}]
  end
end
