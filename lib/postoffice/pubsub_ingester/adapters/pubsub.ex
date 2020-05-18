defmodule Postoffice.PubSubIngester.Adapters.PubSub do
  @behaviour Postoffice.PubSubIngester.Adapters.Impl

  def get(conn, topic_subscription_relation) do
    {:fake}
  end

  def confirm(ackIds) do
    {:fake}
  end
end
