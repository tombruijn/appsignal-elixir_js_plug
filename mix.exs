defmodule Appsignal.JSPlug.Mixfile do
  use Mix.Project

  def project do
    [app: :appsignal_js_plug,
     version: "0.2.2",
     name: "AppSignal JavaScript plug",
     description: description(),
     package: package(),
     source_url: "https://github.com/tombruijn/appsignal-elixir_js_plug",
     homepage_url: "https://appsignal.com",
     elixir: "~> 1.0",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()
    ]
  end

  defp description do
    "AppSignal Plug to send JavaScript errors to AppSignal."
  end

  defp package do
    %{files: ["lib", "mix.exs", "*.md", "LICENSE"],
      maintainers: ["Tom de Bruijn"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/tombruijn/appsignal-elixir_js_plug"}}
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:appsignal, "~> 1.3 and < 2.0.0"},
      {:plug, ">= 1.1.0"},
      {:poison, ">= 1.3.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp elixirc_paths(env) do
    case test?(env) do
      true -> ["lib", "test/support"]
      false -> ["lib"]
    end
  end

  defp test?(:test), do: true
  defp test?(_), do: false
end
