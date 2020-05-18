defmodule Postoffice.PubSubIngester.Adapters.Impl do
  @moduledoc false

  @callback get(conn :: Map, topic_subscription_relation :: Map) :: {:ok, Map} | {:error, reason :: String}
  @callback confirm(ack_ids :: List, conn :: Map) :: {:ok, Map}
  @callback connect() :: Map
end
