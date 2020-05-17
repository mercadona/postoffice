defmodule Postoffice.PubSubIngester.Adapters.Impl do
  @moduledoc false

  @callback get(topic_subscription_relation :: Map) :: {:ok, Map} | {:error, reason :: String}
  @callback confirm(ack_ids :: List) :: {:ok, Map}
end
