defmodule Postoffice.DispatchTest do
  use ExUnit.Case, async: true

  alias Postoffice.Dispatch

  @two_elements_attrs [
    %{name: "element1"},
    %{name: "element2"}
  ]

  def two_elements_queue_fixture() do
    queue = :queue.new()

    Enum.reduce(@two_elements_attrs, queue, fn element, acc ->
      :queue.in(element, acc)
    end)
  end

  describe "Dispatch module" do
    test "Demanding without events on an empty queue returns no events" do
      queue = :queue.new()
      assert Dispatch.dispatch_events(queue, 1, []) == {[], {{[], []}, 1}}
    end

    test "Demanding more than queue size when queue is empty returns the passed demand" do
      queue = :queue.new()
      assert Dispatch.dispatch_events(queue, 3, []) == {[], {{[], []}, 3}}
    end

    test "Queue with two elements, having no elements at that time, returns one element, the updated queue plus remaining demand" do
      queue = two_elements_queue_fixture()

      assert Dispatch.dispatch_events(queue, 1, []) ==
               {[%{name: "element1"}], {{[], [%{name: "element2"}]}, 0}}
    end

    test "Demanding more than queue size left pending demand" do
      queue = two_elements_queue_fixture()

      assert Dispatch.dispatch_events(queue, 3, []) ==
               {[%{name: "element1"}, %{name: "element2"}], {{[], []}, 1}}
    end

    test "Dispatching from queue without demand returns the same queue and no pending demand" do
      queue = two_elements_queue_fixture()

      assert Dispatch.dispatch_events(queue, 0, []) ==
               {[], {{[%{name: "element2"}], [%{name: "element1"}]}, 0}}
    end
  end
end
