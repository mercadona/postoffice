defmodule Postoffice.Starters.Counters do
  use Task

  alias Postoffice.Messaging

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(_arg) do
    :ets.update_counter(:counters, :topics, Messaging.count_topics(), {1, 0})
    :ets.update_counter(:counters, :messages_received, Messaging.count_messages(), {1, 0})
    :ets.update_counter(:counters, :messages_sent, Messaging.count_sent_messages(), {1, 0})
    :ets.update_counter(:counters, :messages_failed, Messaging.count_failed_messages(), {1, 0})
    :ets.update_counter(:counters, :http_publishers, Messaging.count_publishers("http"), {1, 0})

    :ets.update_counter(
      :counters,
      :pubsub_publishers,
      Messaging.count_publishers("pubsub"),
      {1, 0}
    )
  end
end
