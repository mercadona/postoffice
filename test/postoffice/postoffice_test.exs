defmodule Postoffice.PostofficeTest do
  use Postoffice.DataCase, async: true

  alias Postoffice

  describe "Postoffice api" do
    test "ping postoffice application" do
      assert Postoffice.ping() == :ok
    end

    test "receive_message/1 returns error when topic doesnt exist" do
      assert {:relationship_does_not_exists, _error} = Postoffice.receive_message(%{"topic" => "invalid", "payload" => %{"key" => "value"}})
    end
  end
end
