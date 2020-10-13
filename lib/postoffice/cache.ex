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
    warm_up()
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

  defp warm_up() do
    Messaging.list_disabled_publishers()
    |> Enum.map(fn publisher -> publisher.id end)
    |> warm_publishers()
  end

  defp warm_publishers(disabled_publishers_ids) when disabled_publishers_ids == [], do: :ok

  defp warm_publishers(disabled_publishers_ids) do
    ids_tuples = Enum.map(disabled_publishers_ids, fn id -> {id, :disabled} end)
    Cachex.put_many(:postoffice, ids_tuples)
    PubSub.subscribe(Postoffice.PubSub, "publishers")
  end
end
