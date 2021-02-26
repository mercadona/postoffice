defmodule Postoffice.CacheTest do
  use Postoffice.DataCase, async: true

  alias Postoffice.Cache
  alias Postoffice.Fixtures

  @deleted_publisher_attrs %{
    active: false,
    target: "http://fake.target3",
    initial_message: 0,
    type: "http",
    deleted: true
  }

  @disabled_publisher_attrs %{
    active: false,
    target: "http://fake.another.target",
    initial_message: 0,
    type: "http",
    deleted: false
  }

  @active_publisher_attrs %{
    active: true,
    target: "http://fake.last.target3",
    initial_message: 0,
    type: "http",
    deleted: false
  }

  describe "cache" do
    test "initialize cache with publishers" do
      topic = Fixtures.create_topic()
      active_publisher = Fixtures.create_publisher(topic, @active_publisher_attrs)
      deleted_publisher = Fixtures.create_publisher(topic, @deleted_publisher_attrs)
      disabled_publisher = Fixtures.create_publisher(topic, @disabled_publisher_attrs)

      Cache.initialize()

      assert Cachex.get(:postoffice, active_publisher.id) == {:ok, nil}
      assert Cachex.get(:postoffice, disabled_publisher.id) == {:ok, :disabled}
      assert Cachex.get(:postoffice, deleted_publisher.id) == {:ok, :deleted}
    end
  end
end
