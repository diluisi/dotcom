defmodule DotCom.Mixfile do
  use Mix.Project

  def project do
    [apps_path: "apps",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     preferred_cli_env: [coveralls: :test, "coveralls.json": :test],
     test_coverage: [tool: ExCoveralls],
     dialyzer: [
       plt_add_apps: [:mix, :phoenix_live_reload, :laboratory],
       ignore_warnings: ".dialyzer.ignore-warnings"],
     deps: deps(),

     #docs
     name: "MBTA Website",
     source_url: "https://github.com/mbta/dotcom",
     homepage_url: "https://beta.mbta.com/",
     docs: [main: "Site", # The main page in the docs
            logo: "apps/site/assets/assets/images/mbta-logo-t.png"]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps folder
  defp deps do
    [{:credo, ">= 0.7.1", only: [:dev, :test]},
     {:excoveralls, "~> 0.5", only: :test},
     {:ex_doc, "~> 0.14", only: :dev}]
  end

end
