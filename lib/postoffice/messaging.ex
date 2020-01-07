defmodule Postoffice.Messaging do
  @moduledoc """
  The Messaging context.
  """

  import Ecto.Query, warn: false

  alias Postoffice.Repo

  alias Postoffice.Messaging.Message
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
  def list_messages(limit \\ 100) do
    Repo.all(Message, limit: limit)
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
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(topic, attrs \\ %{}) do
    message_assoc = Ecto.build_assoc(topic, :messages, attrs)

    message_assoc
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{source: %Message{}}

  """
  def change_message(%Message{} = message) do
    Message.changeset(message, %{})
  end

  @doc """
  Returns the list of pending messages to be consumed for a topic for a consumer.

  ## Examples

      iex> list_pending_messages_for_publisher(publisher_id, topic_id)
      [%Message{}, ...]

  """
  def list_pending_messages_for_publisher(
        publisher_id,
        topic_id,
        initial_message \\ 0,
        limit \\ 500
      ) do
    query =
      from(
        publisher_success in PublisherSuccess,
        right_join: messages in Message,
        on:
          publisher_success.publisher_id == ^publisher_id and
            publisher_success.message_id == messages.id,
        join: publishers in Publisher,
        on: publishers.id == ^publisher_id,
        select: messages,
        where: is_nil(publisher_success.id),
        where: messages.id > ^initial_message,
        where: messages.topic_id == ^topic_id,
        limit: ^limit,
        select_merge: %{
          publisher_id: publishers.id,
          publisher_type: publishers.type,
          publisher_endpoint: publishers.endpoint
        }
      )

    Repo.all(query)
  end

  def list_topics do
    query = from(t in Topic)

    Repo.all(query)
  end

  def list_publishers do
    query = from(p in Publisher, where: p.active == true, preload: [:topic])

    Repo.all(query)
  end

  def create_publisher_success(attrs \\ %{}) do
    %PublisherSuccess{}
    |> PublisherSuccess.changeset(attrs)
    |> Repo.insert()
  end

  def list_publisher_success(publisher_id) do
    query = from(p in PublisherSuccess, where: p.publisher_id == ^publisher_id)

    Repo.all(query)
  end

  @spec create_publisher_failure(
          :invalid
          | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: any
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
    query = from(t in Topic, where: t.name == ^name)

    Repo.one(query)
  end

  def get_last_message do
    from(m in Message, order_by: [desc: :id], limit: 1)
    |> Repo.one()
  end

  def list_publisher_failures(publisher_id) do
    query = from(p in PublisherFailures, where: p.publisher_id == ^publisher_id)

    Repo.all(query)
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

  def message_already_processed(message_id, publisher_id) do
    query =
      from ps in PublisherSuccess,
        where: ps.publisher_id == ^publisher_id and ps.message_id == ^message_id

    Repo.exists?(query)
  end
end
