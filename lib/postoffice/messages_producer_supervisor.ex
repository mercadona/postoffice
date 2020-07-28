defmodule Postoffice.MessagesProducerSupervisor do
  use ConsumerSupervisor

  require Logger

  def start_link(arg) do
    ConsumerSupervisor.start_link(__MODULE__, arg)
  end

  def init(_arg) do
    children = [
      worker(Postoffice.MessagesProducer, [], restart: :transient)
    ]

    opts = [
      strategy: :one_for_one,
      subscribe_to: [{:publisher_producer, max_demand: 25, min_demand: 1}]
    ]

    ConsumerSupervisor.init(children, opts)
  end
end
