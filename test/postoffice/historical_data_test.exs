defmodule Postoffice.HistoricalDataTest do
  use Postoffice.DataCase

  alias Postoffice.HistoricalData
  alias Postoffice.FakeClock

  describe "sent_messages" do
    alias Postoffice.HistoricalData.SentMessages

    @valid_attrs %{
      attributes: %{"key" => "some attributes"},
      consumer_id: 42,
      message_id: 42,
      payload: [%{"key" => "some payload"}]
    }
    @invalid_attrs %{attributes: nil, consumer_id: nil, message_id: nil, payload: nil}

    def sent_messages_fixture(attrs \\ %{}) do
      {:ok, sent_messages} =
        attrs
        |> Enum.into(@valid_attrs)
        |> HistoricalData.create_sent_messages()

      sent_messages
    end

    test "list_sent_messages/0 returns all sent_messages" do
      sent_messages = sent_messages_fixture()
      assert HistoricalData.list_sent_messages() == [sent_messages]
    end

    test "get_sent_messages!/1 returns the sent_messages with given id" do
      sent_messages = sent_messages_fixture()

      assert HistoricalData.get_sent_message_by_message_id!(sent_messages.message_id) ==
               sent_messages
    end

    test "get_sent_message_by_message_id!/1 returns the sent_messages with given message_id" do
      sent_messages = sent_messages_fixture()

      assert HistoricalData.get_sent_message_by_message_id!(sent_messages.message_id) ==
               sent_messages
    end

    test "create_sent_messages/1 with valid data creates a sent_messages" do
      assert {:ok, %SentMessages{} = sent_messages} =
               HistoricalData.create_sent_messages(@valid_attrs)

      assert sent_messages.attributes == %{"key" => "some attributes"}
      assert sent_messages.consumer_id == 42
      assert sent_messages.message_id == 42
      assert sent_messages.payload == [%{"key" => "some payload"}]
    end

    test "create_sent_messages/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = HistoricalData.create_sent_messages(@invalid_attrs)
    end

    test "delete_sent_messages/1 deletes the sent_messages" do
      sent_messages = sent_messages_fixture()
      assert {:ok, %SentMessages{}} = HistoricalData.delete_sent_messages(sent_messages)

      assert_raise Ecto.NoResultsError, fn ->
        HistoricalData.get_sent_message_by_message_id!(sent_messages.message_id)
      end
    end

    test "change_sent_messages/1 returns a sent_messages changeset" do
      sent_messages = sent_messages_fixture()
      assert %Ecto.Changeset{} = HistoricalData.change_sent_messages(sent_messages)
    end
  end

  describe "failed_messages" do
    alias Postoffice.HistoricalData.FailedMessages

    @valid_attrs %{
      attributes: %{},
      consumer_id: 42,
      message_id: 42,
      payload: [%{}],
      reason: "some reason"
    }
    @invalid_attrs %{
      attributes: nil,
      consumer_id: nil,
      message_id: nil,
      payload: nil,
      reason: nil
    }

    def failed_messages_fixture(attrs \\ %{}) do
      {:ok, failed_messages} =
        attrs
        |> Enum.into(@valid_attrs)
        |> HistoricalData.create_failed_messages()

      failed_messages
    end

    test "list_failed_messages/0 returns all failed_messages" do
      failed_messages = failed_messages_fixture()
      assert HistoricalData.list_failed_messages() == [failed_messages]
    end

    test "list_failed_messages_by_message_id/1 returns the failed_messages with given id" do
      failed_messages = failed_messages_fixture()

      assert HistoricalData.list_failed_messages_by_message_id(failed_messages.message_id) == [
               failed_messages
             ]
    end

    test "create_failed_messages/1 with valid data creates a failed_messages" do
      assert {:ok, %FailedMessages{} = failed_messages} =
               HistoricalData.create_failed_messages(@valid_attrs)

      assert failed_messages.attributes == %{}
      assert failed_messages.consumer_id == 42
      assert failed_messages.message_id == 42
      assert failed_messages.payload == [%{}]
      assert failed_messages.reason == "some reason"
    end

    test "create_failed_messages/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = HistoricalData.create_failed_messages(@invalid_attrs)
    end

    test "delete_failed_messages/1 deletes the failed_messages" do
      failed_messages = failed_messages_fixture()
      assert {:ok, %FailedMessages{}} = HistoricalData.delete_failed_messages(failed_messages)
      assert HistoricalData.list_failed_messages_by_message_id(failed_messages.message_id) == []
    end

    test "change_failed_messages/1 returns a failed_messages changeset" do
      failed_messages = failed_messages_fixture()
      assert %Ecto.Changeset{} = HistoricalData.change_failed_messages(failed_messages)
    end
  end

  describe "clean_messages" do
    alias Postoffice.HistoricalData.SentMessages

    @message_to_delete %{
      attributes: %{"key" => "some attributes"},
      consumer_id: 42,
      message_id: 42,
      payload: [%{"key" => "some payload"}]
    }
    @message_to_preserve %{
      attributes: %{"key" => "some attributes"},
      consumer_id: 43,
      message_id: 43,
      payload: [%{"key" => "some payload"}]
    }

    def clean_messages_fixture(attrs \\ %{}) do
      {:ok, sent_messages} =
        attrs
        |> Enum.into(@message_to_delete)
        |> HistoricalData.create_sent_messages()

      {:ok, sent_messages} =
        attrs
        |> Enum.into(@message_to_preserve)
        |> HistoricalData.create_sent_messages()

    end

    test "cleans historical data" do
      clean_messages_fixture()

      FakeClock.freeze(~U[2021-09-02 23:00:07Z])

      Repo.get_by(SentMessages, message_id: 42)
      |> change(%{inserted_at: ~N[2021-01-03 23:00:07]})
      |> Repo.update()

      message_to_preserve = Repo.get_by(SentMessages, message_id: 43)

      HistoricalData.clean_sent_messages()

      messages_count = Repo.one(from data in SentMessages, select: count(data.id))

      assert messages_count == 1
      assert Repo.one(SentMessages) == message_to_preserve
    end

  end
end
