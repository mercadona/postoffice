defmodule Postoffice.MessagesProducer do
  use GenStage

  alias Postoffice.Dispatch
  alias Postoffice.Messaging
  alias Postoffice.MessagesConsumerSupervisor

  require Logger

  def start_link(publisher) do
    Logger.info("Starting messages producer for publisher", publisher_id: publisher.id)

    GenStage.start_link(__MODULE__, publisher, name: {:via, :swarm, publisher.id})
  end

  def init(publisher) do
    send(self(), {:fetch_publisher_messages, publisher})

    Process.send_after(self(), :maybe_die, publisher.seconds_timeout * 1_000)
    {:producer, %{demand_state: {:queue.new(), 0}, publisher: publisher}}
  end

  def handle_demand(
        incoming_demand,
        %{demand_state: {queue, pending_demand}, publisher: _publisher} = state
      ) do
    {events, demand_state} = Dispatch.dispatch_events(queue, incoming_demand + pending_demand, [])

    state = Map.put(state, :demand_state, demand_state)
    {:noreply, events, state}
  end

  def handle_info(
        {:fetch_publisher_messages, publisher},
        %{demand_state: {queue, pending_demand}, publisher: publisher} = state
      ) do
    MessagesConsumerSupervisor.start_link(publisher.id, self())

    if :queue.len(queue) < 25 do
      pending_messages =
        Messaging.list_pending_messages_for_publisher(publisher.id, messages_quantity(publisher.type))
        |> prepare_pending_messages(publisher)

      queue =
        Enum.reduce(pending_messages, queue, fn publisher_message, acc ->
          :queue.in(%{publisher: publisher, message: publisher_message}, acc)
        end)

      {events, demand_state} = Dispatch.dispatch_events(queue, pending_demand, [])
      state = Map.put(state, :demand_state, demand_state)
      {:noreply, events, state}
    else
      {:noreply, [], state}
    end
  end

  def handle_info(:maybe_die, %{demand_state: {queue, _pending_demand}, publisher: publisher} = state) do
    if :queue.len(queue) == 0 do
      Process.send_after(self(), :die, 500)
    else
      Process.send_after(self(), :maybe_die, publisher.seconds_timeout * 1_000)
    end

    {:noreply, [], state}
  end

  def handle_info(:die, state) do
    {:stop, :normal, state}
  end

  defp prepare_pending_messages(pending_messages, %{type: type} = _publisher)
       when type == "pubsub" do
    Enum.map(pending_messages, fn pending_message -> pending_message.message end)
    |> Enum.chunk_every(100)
  end

  defp prepare_pending_messages(pending_messages, _publisher) do
    Enum.map(pending_messages, fn pending_message -> pending_message.message end)
  end

  defp messages_quantity(type) when type == "pubsub" do
    1000
  end

  defp messages_quantity(_type)do
    300
  end

end
