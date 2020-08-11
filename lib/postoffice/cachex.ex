defmodule Postoffice.Cachex do
  # This process is in charge of keeping a local cache for failed messages so in case of a node
  # is down, the others can continue sending messages with the same restrictions.
  @moduledoc false

  use GenServer
  alias Phoenix.PubSub

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: :postoffice_cachex)
  end

  @impl true
  def init(_args) do
    Process.send_after(self(), :subscribe, 100)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:subscribe, state) do
    PubSub.subscribe(Postoffice.PubSub, "messages")
    {:noreply, state}
  end


  @impl true
  def handle_info({:message_failure, {values, seconds_retry}}, state) when is_list(values) do
    Cachex.put_many(:retry_cache, values, ttl: :timer.seconds(seconds_retry))
    {:noreply, state}
  end

  @impl true
  def handle_info({:message_failure, {publisher_id, pending_message_id, seconds_retry}}, state) do
    Cachex.put(:retry_cache, {publisher_id, pending_message_id}, 1,
      ttl: :timer.seconds(seconds_retry)
    )
    {:noreply, state}
  end
end
