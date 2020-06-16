defmodule Postoffice.Messaging do
  @moduledoc """
  The Messaging context.
  """

  import Ecto.Query, warn: false

  alias Postoffice.Repo

  alias Postoffice.Messaging.Message
  alias Postoffice.Messaging.PendingMessage
  alias Postoffice.Messaging.Publisher
  alias Postoffice.Messaging.PublisherSuccess
  alias Postoffice.Messaging.PublisherFailures
  alias Postoffice.Messaging.Topic

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

  """
  def list_messages(messages_limit \\ 100) do
    Message
    |> limit(^messages_limit)
    |> Repo.all()
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id) do
    from(m in Message, where: m.id == ^id, preload: [:topic])
    |> Repo.one()
  end

  @doc """
  Add a message to deliver marking this as pending.

  ## Examples

      iex> add_message_to_deliver(%{field: value})
      {:ok, %Message{}}

      iex> add_message_to_deliver(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def add_message_to_deliver(topic, attrs \\ %{}) do
    topic =
      topic
      |> Repo.preload(:consumers)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:message, build_message_changeset(topic, attrs))
    |> Ecto.Multi.run(:pending_messages, fn _repo, %{message: message} ->
      insert_pending_messages(topic.consumers, message)
      {:ok, :multiple_insertion}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, result} -> {:ok, result.message}
      {:error, :message, changeset, %{}} -> {:error, changeset}
    end
  end

  defp build_message_changeset(topic, message) when is_list(message) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Enum.map(message, fn message_attrs ->
      Map.merge(message_attrs, %{topic_id: topic.id, inserted_at: now, updated_at: now})
    end)
  end

  defp build_message_changeset(topic, message) do
    Ecto.build_assoc(topic, :messages, message)
    |> Message.changeset(message)
  end

  defp insert_pending_messages(consumers, message) do
    Enum.each(consumers, fn consumer ->
      %PendingMessage{publisher_id: consumer.id, message_id: message.id}
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:publisher, consumer)
      |> Ecto.Changeset.put_assoc(:message, message)
      |> PendingMessage.changeset(%{})
      |> Repo.insert!()
    end)
  end

  def add_messages_to_deliver(topic_name, messages_attrs) do
    case __MODULE__.get_topic(topic_name) |> Repo.preload(:consumers) do
      nil ->
        {:error, "Topic does not exist"}

      topic ->
        Ecto.Multi.new()
        |> Ecto.Multi.insert_all(
          :message,
          Message,
          build_message_changeset(topic, messages_attrs),
          returning: [:id]
        )
        |> Ecto.Multi.run(:pending_messages, fn _repo, message ->
          insert_bulk_pending_messages(topic.consumers, message)
          {:ok, :multiple_insertion}
        end)
        |> Repo.transaction()
        |> case do
          {:ok, result} -> {:ok, result.message}
          {:error, :message, changeset, %{}} -> {:error, changeset}
        end
    end
  end

  defp insert_bulk_pending_messages(consumers, data) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    message = data.message |> elem(1)

    pending_messages =
      Enum.map(message, fn m ->
        Enum.map(consumers, fn consumer ->
          %{publisher_id: consumer.id, message_id: m.id, inserted_at: now, updated_at: now}
        end)
      end)
      |> List.first()

    Ecto.Multi.new()
    |> Ecto.Multi.insert_all(:pending_messages, PendingMessage, pending_messages)
    |> Repo.transaction()
  end

  @doc """
  Returns the list of pending messages to be consumed for a topic for a consumer.

  ## Examples

      iex> list_pending_messages_for_publisher(publisher_id,)
      [%Message{}, ...]

  """
  def list_pending_messages_for_publisher(publisher_id, limit \\ 300) do
    from(pm in PendingMessage,
      where: pm.publisher_id == ^publisher_id,
      limit: ^limit,
      preload: [:message, :publisher]
    )
    |> Repo.all()
  end

  def list_topics do
    from(t in Topic)
    |> Repo.all()
  end

  def list_enabled_publishers do
    from(p in Publisher, where: p.active == true, preload: [:topic])
    |> Repo.all()
  end

  def list_publishers do
    from(p in Publisher, preload: [:topic])
    |> Repo.all()
  end

  def create_publisher_success(%{publisher_id: publisher_id, message_id: message_id} = _attrs)
      when is_list(message_id) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Enum.map(message_id, fn id ->
      %{publisher_id: publisher_id, message_id: id, inserted_at: now, updated_at: now}
    end)
  end

  def create_publisher_success(attrs) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    attrs
    |> Map.put(:inserted_at, now)
    |> Map.put(:updated_at, now)
    |> List.wrap()
  end

  @spec mark_message_as_delivered(%{message_id: any, publisher_id: any}) :: {:ok, :finished}
  def mark_message_as_delivered(message_information) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert_all(
      :publisher_success,
      PublisherSuccess,
      create_publisher_success(message_information)
    )
    |> Ecto.Multi.delete_all(
      :pending_messages,
      delete_pending_message(message_information)
    )
    |> Repo.transaction()

    {:ok, :finished}
  end

  defp delete_pending_message(%{publisher_id: publisher_id, message_id: message_id})
        when is_list(message_id) do
    from(p in PendingMessage,
      where:
        p.publisher_id == ^publisher_id and
          p.message_id in ^message_id
    )
  end

  defp delete_pending_message(%{publisher_id: publisher_id, message_id: message_id}) do
    from(p in PendingMessage,
      where:
        p.publisher_id == ^publisher_id and
          p.message_id == ^message_id
    )
  end

  def list_publisher_success(publisher_id) do
    from(p in PublisherSuccess, where: p.publisher_id == ^publisher_id)
    |> Repo.all()
  end

  def create_publisher_failure(
        %{publisher_id: publisher_id, message_id: message_id, reason: reason} = _attrs
      )
      when is_list(message_id) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    failures =
      Enum.map(message_id, fn id ->
        %{
          publisher_id: publisher_id,
          message_id: id,
          reason: reason,
          inserted_at: now,
          updated_at: now
        }
      end)

    Ecto.Multi.new()
    |> Ecto.Multi.insert_all(:failures, PublisherFailures, failures)
    |> Repo.transaction()
  end

  def create_publisher_failure(attrs) do
    %PublisherFailures{}
    |> PublisherFailures.changeset(attrs)
    |> Repo.insert()
  end

  def create_publisher(attrs \\ %{}) do
    %Publisher{}
    |> Publisher.changeset(attrs)
    |> Repo.insert()
  end

  def create_topic(attrs \\ %{}) do
    %Topic{}
    |> Topic.changeset(attrs)
    |> Repo.insert()
  end

  def get_publisher!(id) do
    from(p in Publisher, where: p.id == ^id, preload: [:topic])
    |> Repo.one()
  end

  def change_publisher(%Publisher{} = publisher) do
    Publisher.changeset(publisher, %{})
  end

  def get_topic(name) do
    from(t in Topic, where: t.name == ^name)
    # |> Repo.preload(:consumers)
    |> Repo.one()
  end

  def get_last_message do
    from(m in Message, order_by: [desc: :id], limit: 1)
    |> Repo.one()
  end

  def list_publisher_failures(publisher_id) do
    from(p in PublisherFailures, where: p.publisher_id == ^publisher_id)
    |> Repo.all()
  end

  def count_topics do
    Repo.aggregate(from(t in "topics"), :count, :id)
  end

  def count_publishers() do
    Repo.aggregate(from(p in "publishers"), :count)
  end

  def count_pending_messages do
    Repo.aggregate(from(ps in "pending_messages"), :count)
  end

  def count_publishers_failures do
    Repo.aggregate(from(ps in "publisher_failures"), :count)
  end

  def get_publisher_success_for_message(message_id) do
    from(p in PublisherSuccess, where: p.message_id == ^message_id, preload: [:publisher])
    |> Repo.all()
  end

  def get_publisher_failures_for_message(message_id) do
    from(p in PublisherFailures, where: p.message_id == ^message_id)
    |> Repo.all()
  end

  def get_recovery_hosts() do
    from(t in Topic, where: t.recovery_enabled == true, distinct: true, select: t.origin_host)
    |> Repo.all()
  end

  @doc """
  Returns an integer representing an estimated count from the given schema.

  ## Examples

      iex> get_estimate_count("messages")
      0

  """
  def get_estimated_count(schema) do
    Ecto.Adapters.SQL.query!(
      Postoffice.Repo,
      "SELECT reltuples::bigint FROM pg_catalog.pg_class WHERE relname = $1;",
      [schema]
    ).rows
    |> List.first()
    |> List.first()
  end

  @doc """
  Returns an integer representing a count of publisher failures. This value is agregated by publisher and message.

  ## Examples

      iex> count_publishers_failures_aggregated()
      10

  """
  def count_publishers_failures_aggregated() do
    Ecto.Adapters.SQL.query!(
      Postoffice.Repo,
      "select COUNT(*) from publisher_failures group by publisher_id, message_id;"
    ).num_rows
  end
end
