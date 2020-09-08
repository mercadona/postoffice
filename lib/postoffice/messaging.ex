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

  def add_messages_to_deliver(topic_name, messages_attrs) do
    case get_topic(topic_name) |> Repo.preload(:consumers) do
      nil ->
        {:error, "Topic does not exist"}

      topic ->
        Enum.map(messages_attrs, fn attrs ->
          Enum.map(topic.consumers, fn consumer ->
            generate_job_changeset(consumer, attrs)
          end)
        end)
        |> Enum.flat_map(fn elem -> elem end)
        |> insert_job_changesets()
    end
  end

  defp generate_job_changeset(consumer, job_attrs) do
    attrs =
      Map.put_new(job_attrs, "target", consumer.target) |> Map.put_new("consumer_id", consumer.id)

    case consumer.type do
      "http" ->
        attrs = Map.put_new(attrs, "timeout", consumer.seconds_timeout)
        HttpWorker.new(attrs)

      "pubsub" ->
        PubsubWorker.new(attrs)
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
end
