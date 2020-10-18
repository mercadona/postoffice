defmodule Postoffice.Messaging do
  @moduledoc """
  The Messaging context.
  """

  import Ecto.Query, warn: false

  alias Postoffice.Repo

  alias Postoffice.HttpWorker
  alias Postoffice.PubsubWorker
  alias Postoffice.Messaging.Message
  alias Postoffice.Messaging.Publisher
  alias Postoffice.Messaging.Topic

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
    topic = topic |> Repo.preload(:consumers)

    insert_job_changesets(
      for consumer <- topic.consumers, do: generate_job_changeset(consumer, attrs)
    )
  end

  def add_messages_to_deliver(%{"topic" => topic} = params) do
    case get_topic(topic) |> Repo.preload(:consumers) do
      nil ->
        {:error, "Topic does not exist"}
      topic ->
        Enum.map(topic.consumers, fn consumer ->
          generate_jobs_for_messages(consumer, params)
        end)
        |> Enum.flat_map(fn elem -> elem end)
        |> insert_job_changesets()
    end
  end

  def schedule_message(
        %{
          "topic" => topic_name,
          "attributes" => attributes,
          "payload" => payload,
          "schedule_at" => schedule_at
        } = _message_params
      ) do
    case get_topic(topic_name) |> Repo.preload(:consumers) do
      nil ->
        {:relationship_does_not_exists, %{topic: ["is invalid"]}}

      topic ->
        insert_job_changesets(
          for consumer <- topic.consumers,
              do: schedule_job_changeset(consumer, payload, attributes, schedule_at)
        )
    end
  end

  defp generate_jobs_for_messages(
         consumer,
         %{"topic" => topic, "attributes" => attributes, "payload" => payloads} = _messages_attrs
       ) do
    attrs = %{
      "topic" => topic,
      "attributes" => attributes,
      "consumer_id" => consumer.id,
      "target" => consumer.target
    }

    case consumer.type do
      "http" ->
        Enum.map(payloads, fn payload ->
          attrs
          |> Map.put("payload", payload)
          |> Map.put("timeout", consumer.seconds_timeout || 30)
          |> HttpWorker.new()
        end)

      "pubsub" ->
        chunk_size = consumer.chunk_size || 20

        Enum.chunk_every(payloads, chunk_size)
        |> Enum.map(fn payload ->
          attrs
          |> Map.put("payload", payload)
          |> PubsubWorker.new()
        end)
    end
  end

  defp generate_job_changeset(consumer, job_attrs) do
    attrs =
      Map.put_new(job_attrs, "target", consumer.target) |> Map.put_new("consumer_id", consumer.id)

    case consumer.type do
      "http" ->
        Map.put(attrs, "timeout", consumer.seconds_timeout || 30)
        |> HttpWorker.new()

      "pubsub" ->
        PubsubWorker.new(attrs)
    end
  end

  defp schedule_job_changeset(consumer, payload, attributes, schedule_at) do
    attrs = %{
      "payload" => payload,
      "attributes" => attributes,
      "target" => consumer.target,
      "consumer_id" => consumer.id
    }

    {:ok, schedule, _offset} = DateTime.from_iso8601(schedule_at)

    case consumer.type do
      "http" ->
        Map.put(attrs, "timeout", consumer.seconds_timeout || 30)
        |> HttpWorker.new(scheduled_at: schedule)

      "pubsub" ->
        PubsubWorker.new(attrs, scheduled_at: schedule)
    end
  end

  defp insert_job_changesets(changesets) do
    Ecto.Multi.new()
    |> Oban.insert_all(:jobs, changesets)
    |> Repo.transaction()
    |> case do
      {:ok, result} ->
        {:ok, extract_job_ids(result)}

      {:error, :message, changeset, %{}} ->
        {:error, changeset}
    end
  end

  defp extract_job_ids(jobs) do
    Enum.reduce(jobs[:jobs], [], fn job, acc -> [job.id | acc] end)
  end

  def list_topics do
    from(t in Topic)
    |> Repo.all()
  end

  def list_publishers do
    from(p in Publisher, preload: [:topic])
    |> Repo.all()
  end

  @spec list_disabled_publishers :: any
  def list_disabled_publishers do
    from(p in Publisher, where: p.active == false)
    |> Repo.all()
  end

  def create_publisher(attrs \\ %{}) do
    case insert_publisher(attrs) do
      {:ok, publisher} ->
        broadcast_publisher({:ok, publisher}, :publisher_updated)
        {:ok, publisher}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp insert_publisher(attrs) do
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

  def update_publisher(changeset) do
    Repo.update(changeset)
    |> broadcast_publisher(:publisher_updated)
  end

  def get_topic(name) do
    from(t in Topic, where: t.name == ^name)
    |> Repo.one()
  end

  def get_last_message do
    from(m in Message, order_by: [desc: :id], limit: 1)
    |> Repo.one()
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

  def count_failing_jobs() do
    Ecto.Adapters.SQL.query!(
      Postoffice.Repo,
      "SELECT COUNT(*) from oban_jobs where state = 'retryable'"
    ).rows
    |> List.first()
    |> List.first()
  end

  defp broadcast_publisher({:ok, publisher}, event) do
    Phoenix.PubSub.broadcast(
      Postoffice.PubSub,
      "publishers",
      {event, publisher}
    )

    {:ok, publisher}
  end
end
