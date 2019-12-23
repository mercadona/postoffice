defmodule Postoffice.Dispatch do
  require Logger

  def dispatch_events(queue, 0, events) do
    {Enum.reverse(events), {queue, 0}}
  end

  def dispatch_events(queue, demand, events) do
    case :queue.out(queue) do
      {{:value, event}, queue} ->
        dispatch_events(queue, demand - 1, [event | events])

      {:empty, queue} ->
        {Enum.reverse(events), {queue, demand}}
    end
  end
end
