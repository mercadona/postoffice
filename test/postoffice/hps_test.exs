defmodule Postoffice.PostofficeTest do
  use Postoffice.DataCase

  alias Postoffice

  describe "PostofficeWeb external api" do
    test "invalid UUID returns nil" do
      assert Postoffice.find_message_by_uuid(123) == nil
    end
  end
end
