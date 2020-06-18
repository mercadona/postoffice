defmodule Postoffice.MessagesConsumerSupervisor do
  use ConsumerSupervisor

  require Logger

  def start_link(publisher_id, pid_to_subscribe) do
    name = name(publisher_id)
    Logger.info("Trying to start message consumer supervisor for publisher #{publisher_id}")
    ConsumerSupervisor.start_link(__MODULE__, {pid_to_subscribe, publisher_id}, name: name)
  end

  def name(publisher_id) do
    {:via, :swarm, "message_consumer_suppervisor-#{publisher_id}"}
  end

  def init({pid_to_subscribe, _publisher_id}) do
    children = [
      worker(Postoffice.MessagesConsumer, [], restart: :transient)
    ]

    opts = [
      strategy: :one_for_one,
      subscribe_to: [{pid_to_subscribe, max_demand: 25, min_demand: 1}]
    ]

    ConsumerSupervisor.init(children, opts)
  end
end
