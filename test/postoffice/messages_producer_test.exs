defmodule Postoffice.MessagesProducerTest do
  use Postoffice.DataCase, async: true

  import Mox

  alias Postoffice.Fixtures
  alias Postoffice.MessagesProducer

  setup [:set_mox_from_context, :verify_on_exit!]

  describe "MessagesProducer tests" do
    test "handle demand returns no message when state queue is empty" do
      topic = Fixtures.create_topic()
      existing_publisher = Fixtures.create_publisher(topic)

      {:noreply, messages, %{demand_state: {queue, pending_demand}, publisher: _publisher}} =
        MessagesProducer.handle_demand(1, %{
          demand_state: {:queue.new(), 0},
          publisher: existing_publisher
        })

      assert messages == []
      assert pending_demand == 1
      assert :queue.len(queue) == 0
    end

    test "handle demand returns the required amount of data" do
      topic = Fixtures.create_topic()
      existing_publisher = Fixtures.create_publisher(topic)
      message = Fixtures.add_message_to_deliver(topic)
      state_queue = :queue.new()
      state_queue = :queue.in(message, state_queue)
      state_queue = :queue.in(message, state_queue)

      {:noreply, events, %{demand_state: {queue, pending_demand}, publisher: _publisher}} =
        MessagesProducer.handle_demand(1, %{
          demand_state: {state_queue, 0},
          publisher: existing_publisher
        })

      assert pending_demand == 0
      assert :queue.len(queue) == 1
      assert events == [message]
    end
  end
end
