defmodule Postoffice.MessagesProducer do
  use GenStage

  alias Postoffice.Dispatch
  alias Postoffice.Messaging
  alias Postoffice.MessagesConsumerSupervisor

  require Logger

  @check_empty_queue_time 1000 * 4

  def start_link(publisher) do
    Logger.info(
      "Starting messages producer for publisher #{publisher.id} #{inspect(self())}"
    )

    GenStage.start_link(__MODULE__, publisher, name: {:via, :swarm, publisher.id})
  end

  def init(publisher) do
    send(self(), {:fetch_publisher_messages, publisher})

    Process.send_after(self(), :maybe_die, @check_empty_queue_time)
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
      publisher_messages =
        Messaging.list_pending_messages_for_publisher(
          publisher.id,
          publisher.topic_id,
          publisher.initial_message,
          500
        )

      queue =
        Enum.reduce(publisher_messages, queue, fn publisher_message, acc ->
          :queue.in(publisher_message, acc)
        end)

      {events, demand_state} = Dispatch.dispatch_events(queue, pending_demand, [])
      state = Map.put(state, :demand_state, demand_state)
      {:noreply, events, state}
    else
      {:noreply, [], state}
    end
  end

  def handle_info(:maybe_die, %{demand_state: {queue, _pending_demand}} = state) do
    if :queue.len(queue) == 0 do
      Process.send_after(self(), :die, 1000)
    else
      Process.send_after(self(), :maybe_die, @check_empty_queue_time)
    end

    {:noreply, [], state}
  end

  def handle_info(:die, state) do
    {:stop, :normal, state}
  end
end
