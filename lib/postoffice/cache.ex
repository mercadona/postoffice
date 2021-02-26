defmodule Postoffice.Cache do
  use GenServer
  alias Phoenix.PubSub

  alias Postoffice.Messaging

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: :disabled_publishers_cachex)
  end

  @impl true
  def init(_args) do
    Cachex.start_link(:postoffice, [])
    initialize()
    {:ok, %{}}
  end

  @impl true
  def handle_info({:publisher_updated, publisher}, state) do
    case publisher.active do
      false ->
        Cachex.put(:postoffice, publisher.id, :disabled)

      true ->
        Cachex.del(:postoffice, publisher.id)
    end

    {:noreply, state}
  end

  def initialize() do
    Messaging.list_disabled_publishers()
    |> Enum.map(fn publisher -> publisher.id end)
    |> add_publishrers(:disabled)

    Messaging.list_deleted_publishers()
    |> Enum.map(fn publisher -> publisher.id end)
    |> add_publishrers(:deleted)
  end

  defp add_publishrers(disabled_publishers_ids, state) when disabled_publishers_ids == [], do: :ok

  defp add_publishrers(disabled_publishers_ids, state) do
    ids_tuples = Enum.map(disabled_publishers_ids, fn id -> {id, state} end)
    Cachex.put_many(:postoffice, ids_tuples)
    PubSub.subscribe(Postoffice.PubSub, "publishers")
  end
end
