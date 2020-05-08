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

  def create_publisher_success(attrs \\ %{}) do
    %PublisherSuccess{}
    |> PublisherSuccess.changeset(attrs)
  end

  def mark_message_as_delivered(message_information) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:publisher_success, create_publisher_success(message_information))
    |> Ecto.Multi.delete_all(
      :pending_messages,
      delete_pending_message(message_information)
    )
    |> Repo.transaction()

    {:ok, :finished}
  end

  defp delete_pending_message(message_information) do
    from(p in PendingMessage,
      where:
        p.publisher_id == ^message_information.publisher_id and
          p.message_id == ^message_information.message_id
    )
  end

  def list_publisher_success(publisher_id) do
    from(p in PublisherSuccess, where: p.publisher_id == ^publisher_id)
    |> Repo.all()
  end

  def create_publisher_failure(attrs \\ %{}) do
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

  def get_message_by_uuid(message_uuid) do
    from(m in Message, where: m.public_id == ^message_uuid)
    |> Repo.one()
  end

  def count_topics do
    Repo.aggregate(from(t in "topics"), :count, :id)
  end

  def count_messages do
    Repo.aggregate(from(m in "messages"), :count, :id)
  end

  def count_publishers() do
    Repo.aggregate(from(p in "publishers"), :count, :id)
  end

  def count_published_messages do
    Repo.aggregate(from(ps in "publisher_success"), :count, :id)
  end

  def count_publishers_failures do
    Repo.aggregate(from(ps in "publisher_failures"), :count, :id)
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
    IO.puts(schema)
    Ecto.Adapters.SQL.query!(
      Postoffice.Repo,
      "SELECT reltuples::bigint FROM pg_catalog.pg_class WHERE relname = $1;", [schema]
    ).rows
    |> List.first
    |> List.first
  end
end
