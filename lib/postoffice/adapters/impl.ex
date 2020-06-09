defmodule Postoffice.Adapters.Impl do
  @moduledoc false

  alias Postoffice.Messaging.Publisher

  @callback publish(Publisher, any) :: {:ok, any} | {:error, reason :: String}
end
