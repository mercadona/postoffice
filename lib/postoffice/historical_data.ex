defmodule Postoffice.HistoricalData do
  @moduledoc """
  The HistoricalData context.
  """

  import Ecto.Query, warn: false
  alias Postoffice.Repo

  alias Postoffice.HistoricalData.SentMessages

  @doc """
  Returns the list of sent_messages.

  ## Examples

      iex> list_sent_messages()
      [%SentMessages{}, ...]

  """
  def list_sent_messages do
    Repo.all(SentMessages)
  end

  @doc """
  Gets a single sent_messages.

  Raises `Ecto.NoResultsError` if the Sent messages does not exist.

  ## Examples

      iex> get_sent_messages!(123)
      %SentMessages{}

      iex> get_sent_messages!(456)
      ** (Ecto.NoResultsError)

  """
  def get_sent_messages!(id), do: Repo.get!(SentMessages, id)

  @doc """
  Creates a sent_messages.

  ## Examples

      iex> create_sent_messages(%{field: value})
      {:ok, %SentMessages{}}

      iex> create_sent_messages(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_sent_messages(attrs \\ %{}) do
    %SentMessages{}
    |> SentMessages.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a sent_messages.

  ## Examples

      iex> delete_sent_messages(sent_messages)
      {:ok, %SentMessages{}}

      iex> delete_sent_messages(sent_messages)
      {:error, %Ecto.Changeset{}}

  """
  def delete_sent_messages(%SentMessages{} = sent_messages) do
    Repo.delete(sent_messages)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sent_messages changes.

  ## Examples

      iex> change_sent_messages(sent_messages)
      %Ecto.Changeset{data: %SentMessages{}}

  """
  def change_sent_messages(%SentMessages{} = sent_messages, attrs \\ %{}) do
    SentMessages.changeset(sent_messages, attrs)
  end

  alias Postoffice.HistoricalData.FailedMessages

  @doc """
  Returns the list of failed_messages.

  ## Examples

      iex> list_failed_messages()
      [%FailedMessages{}, ...]

  """
  def list_failed_messages do
    Repo.all(FailedMessages)
  end

  @doc """
  Gets a single failed_messages.

  Raises `Ecto.NoResultsError` if the Failed messages does not exist.

  ## Examples

      iex> get_failed_messages!(123)
      %FailedMessages{}

      iex> get_failed_messages!(456)
      ** (Ecto.NoResultsError)

  """
  def get_failed_messages!(id), do: Repo.get!(FailedMessages, id)

  @doc """
  Creates a failed_messages.

  ## Examples

      iex> create_failed_messages(%{field: value})
      {:ok, %FailedMessages{}}

      iex> create_failed_messages(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_failed_messages(attrs \\ %{}) do
    %FailedMessages{}
    |> FailedMessages.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a failed_messages.

  ## Examples

      iex> update_failed_messages(failed_messages, %{field: new_value})
      {:ok, %FailedMessages{}}

      iex> update_failed_messages(failed_messages, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_failed_messages(%FailedMessages{} = failed_messages, attrs) do
    failed_messages
    |> FailedMessages.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a failed_messages.

  ## Examples

      iex> delete_failed_messages(failed_messages)
      {:ok, %FailedMessages{}}

      iex> delete_failed_messages(failed_messages)
      {:error, %Ecto.Changeset{}}

  """
  def delete_failed_messages(%FailedMessages{} = failed_messages) do
    Repo.delete(failed_messages)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking failed_messages changes.

  ## Examples

      iex> change_failed_messages(failed_messages)
      %Ecto.Changeset{data: %FailedMessages{}}

  """
  def change_failed_messages(%FailedMessages{} = failed_messages, attrs \\ %{}) do
    FailedMessages.changeset(failed_messages, attrs)
  end
end
