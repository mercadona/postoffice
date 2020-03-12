defmodule Postoffice.Rescuer.Producer do
  use GenStage
  require Logger

  alias Postoffice.Dispatch
  alias Postoffice.Messaging
  alias Postoffice.MessagesConsumerSupervisor

  @rescuer_interval 1000 * 30

  def start_link(_args) do
    Logger.info("Starting rescuer producer")
    GenStage.start_link(__MODULE__, :ok, name: :rescuer_producer)
  end

  @impl true
  def init(:ok) do
    send(self(), :populate_state)

    {:producer, {:queue.new(), 0}}
  end

  @impl true
  def handle_demand(incoming_demand, {queue, pending_demand}) do
    {events, state} = Dispatch.dispatch_events(queue, incoming_demand + pending_demand, [])

    {:noreply, events, state}
  end

  @impl true
  def handle_info(:populate_state, {queue, pending_demand} = state) do
    Process.send_after(self(), :populate_state, @rescuer_interval)

    hosts = Messaging.get_recovery_hosts()

    queue =
      Enum.reduce(hosts, queue, fn host, acc ->
        :queue.in(host, acc)
      end)

    {events, state} = Dispatch.dispatch_events(queue, pending_demand, [])
    {:noreply, events, state}
  end
end
