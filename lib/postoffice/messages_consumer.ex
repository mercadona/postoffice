defmodule Postoffice.MessagesConsumer do
  require Logger

  alias __MODULE__
  alias Postoffice.Handlers.Http
  alias Postoffice.Handlers.Pubsub

  def start_link(message) do
    %{
      publisher_type: publisher_type,
      publisher_target: publisher_target,
      publisher_id: publisher_id
    } = message

    Task.start_link(MessagesConsumer.get_handler_module(publisher_type), :run, [
      publisher_target,
      publisher_id,
      message
    ])
  end

  def get_handler_module(type) when type == "http", do: Http
  def get_handler_module(type) when type == "pubsub", do: Pubsub
end
