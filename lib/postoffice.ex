defmodule Postoffice do
  @moduledoc """
  Postoffice keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  require Logger

  alias Postoffice.Messaging

  def receive_message(message_params) do
    {%{"topic" => topic}, message_attrs} = Map.split(message_params, ["topic"])
    topic = Messaging.get_topic(topic)

    Messaging.create_message(
      topic,
      Map.put_new(message_attrs, "public_id", Ecto.UUID.generate())
    )
  end

  def create_topic(topic_params) do
    Messaging.create_topic(topic_params)
  end

  def create_publisher(%{"from_now" => from_now} = publisher_params) when from_now == "true" do
    %{id: id} = Messaging.get_last_message()
    add_publisher(publisher_params, id)
  end

  def create_publisher(publisher_params) do
    add_publisher(publisher_params, 0)
  end

  defp add_publisher(params, initial_message_id) do
    {_value, publisher_params} = Map.pop(params, "from_now")

    {:ok, publisher} =
      Map.put(publisher_params, "initial_message", initial_message_id)
      |> Messaging.create_publisher()

    :ets.update_counter(:counters, :publishers, 1, {1, 0})
    increment_publisher_type_counter(publisher_params)
    {:ok, publisher}
  end

  defp increment_publisher_type_counter(%{"type" => type} = _params) when type == "pubsub",
    do: :ets.update_counter(:counters, :pubsub_publishers, 1, {1, 0})

  defp increment_publisher_type_counter(%{"type" => type} = _params) when type == "http",
    do: :ets.update_counter(:counters, :http_publishers, 1, {1, 0})

  def find_message_by_uuid(uuid) do
    case Ecto.UUID.cast(uuid) do
      :error ->
        nil
      _ok ->
        Messaging.get_message_by_uuid(uuid)
    end
  end

  def get_message(id), do: Messaging.get_message!(id)

  def get_message_success(message_id), do: Messaging.get_publisher_success_for_message(message_id)

  def get_message_failures(message_id),
    do: Messaging.get_publisher_failures_for_message(message_id)

  def count_received_messages do
    case :ets.lookup(:counters, :messages_received) do
      [{:messages_received, messages}] ->
        messages

      [] ->
        0
    end
  end

  def count_sent_messages do
    case :ets.lookup(:counters, :messages_sent) do
      [{:messages_sent, sent}] ->
        sent

      [] ->
        0
    end
  end

  def count_failed_messages do
    case :ets.lookup(:counters, :messages_failed) do
      [{:messages_failed, failed}] ->
        failed

      [] ->
        0
    end
  end

  def count_http_publishers do
    case :ets.lookup(:counters, :http_publishers) do
      [{:http_publishers, http_publishers}] ->
        http_publishers

      [] ->
        0
    end
  end

  def count_pubsub_publishers do
    case :ets.lookup(:counters, :pubsub_publishers) do
      [{:pubsub_publishers, pubsub_publishers}] ->
        pubsub_publishers

      [] ->
        0
    end
  end

  def count_topics do
    case :ets.lookup(:counters, :topics) do
      [{:topics, topics}] ->
        topics

      [] ->
        0
    end
  end

  def ping do
    case :ets.whereis(:counters) do
      :undefined ->
        :ko

      _reference ->
        :ok
    end
  end
end
