defmodule Postoffice.PublisherProducer do
  use GenStage
  require Logger

  alias Postoffice.Messaging
  alias Postoffice.Dispatch

  @repopulate_state_interval 1000 * 10

  def start_link(_args) do
    Logger.info("Starting publishers producer")
    GenStage.start_link(__MODULE__, :ok, name: :publisher_producer)
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
    Process.send_after(self(), :populate_state, @repopulate_state_interval)

    if :queue.len(queue) < 25 do
      publishers = Messaging.list_enabled_publishers()

      queue =
        Enum.reduce(publishers, queue, fn publisher, acc ->
          :queue.in(publisher, acc)
        end)

      {events, state} = Dispatch.dispatch_events(queue, pending_demand, [])
      {:noreply, events, state}
    else
      {:noreply, [], state}
    end
  end
end
