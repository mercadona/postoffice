defmodule Postoffice.PubSubIngester.Adapters.Impl do
  @moduledoc false

  @callback get(topic_subscription_relation :: Map) :: {:ok, list} | {:error, reason :: String}
end
