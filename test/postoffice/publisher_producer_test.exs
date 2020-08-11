defmodule Postoffice.PublisherProducerTest do
  use Postoffice.DataCase, async: true

  import Mox

  alias Postoffice.Fixtures
  alias Postoffice.PublisherProducer

  setup [:set_mox_from_context, :verify_on_exit!]

  describe "PublisherProducer tests" do
    test "no publisher loaded if there is no active publisher" do
      {:noreply, publishers, {queue, pending_demand}} =
        PublisherProducer.handle_info(:populate_state, {:queue.new(), 0})

      assert publishers == []
      assert :queue.len(queue) == 0
      assert pending_demand == 0
    end

    test "active publisher loaded on internal state and ready to be consumed" do
      topic = Fixtures.create_topic()
      _existing_publisher = Fixtures.create_publisher(topic)

      {:noreply, publishers, {queue, pending_demand}} =
        PublisherProducer.handle_info(:populate_state, {:queue.new(), 0})

      assert publishers == []
      assert :queue.len(queue) == 1
      assert pending_demand == 0
    end

    test "handle_demand returns active publisher loaded if present in state" do
      topic = Fixtures.create_topic()
      existing_publisher = Fixtures.create_publisher(topic)
      state_queue = :queue.new()
      state_queue = :queue.in(existing_publisher, state_queue)

      {:noreply, publishers, {queue, pending_demand}} =
        PublisherProducer.handle_demand(1, {state_queue, 0})

      assert Kernel.length(publishers) == 1
      publisher = publishers |> hd
      assert publisher.id == existing_publisher.id
      assert :queue.len(queue) == 0
      assert pending_demand == 0
    end
  end
end
