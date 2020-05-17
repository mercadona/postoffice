defmodule Postoffice.PubSubIngester.Adapters.PubSub do
  @behaviour Postoffice.PubSubIngester.Adapters.Impl

  def get(subscription) do
    {:fake}
  end

  def confirm(ackIds) do
    {:fake}
  end
end
