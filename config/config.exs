use Mix.Config

defmodule FakeAppsignal do
  def plug? do
    true
  end
end

config :appsignal, appsignal_transaction: Appsignal.FakeTransaction
config :appsignal, appsignal: FakeAppsignal
