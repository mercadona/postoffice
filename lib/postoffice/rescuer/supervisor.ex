defmodule Postoffice.Rescuer.Supervisor do
  use ConsumerSupervisor

  require Logger

  def start_link(arg) do
    ConsumerSupervisor.start_link(__MODULE__, arg)
  end

  def init(_arg) do
    children = [
      worker(Postoffice.Rescuer.Consumer, [], restart: :transient)
    ]

    opts = [strategy: :one_for_one, subscribe_to: [{:rescuer_producer, max_demand: 5}]]
    ConsumerSupervisor.init(children, opts)
  end
end

