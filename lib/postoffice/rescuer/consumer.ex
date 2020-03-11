defmodule Postoffice.Rescuer.Consumer do
  use GenStage

  alias Postoffice.Rescuer.MessageRecovery

  require Logger

  def start_link(host) do
    Logger.info("Starting rescuer for host #{host}")

    GenStage.start_link(__MODULE__, host, name: {:via, :swarm, host})

    Task.start_link(MessageRecovery, :run, [
      host
    ])
  end

  def init(:ok) do
    {:consumer, %{}}
  end
end
