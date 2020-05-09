defmodule Postoffice.PubSubIngester.PubSubIngesterTest do
  use Postoffice.DataCase, async: true
  use ExUnit.Case, async: true

  import Mox

  alias Postoffice.Fixtures
  alias Postoffice.Messaging
  alias Postoffice.Messaging.PendingMessage
  alias Postoffice.PubSubIngester.PubSubIngester

  setup [:set_mox_from_context, :verify_on_exit!]

  # setup do
  #   :ok = Ecto.Adapters.SQL.Sandbox.checkout(Postoffice.Repo)
  # end

  describe "pubsub ingester" do
    test "no message created if no undelivered message found" do
      PubSubIngester.run('topic-name')

      assert Messaging.list_messages() == []
    end
    test "create message when is ingested" do
      PubSubIngester.run('topic-name')

      assert length(Repo.all(PendingMessage)) == 1
    end
  end
end
