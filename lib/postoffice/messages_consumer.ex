defmodule Postoffice.MessagesConsumer do
  require Logger

  alias __MODULE__
  alias Postoffice.Handlers.Http
  alias Postoffice.Handlers.Pubsub

  def start_link(pending_message) do
    Task.start_link(MessagesConsumer.get_handler_module(pending_message.publisher.type), :run, [
      pending_message.publisher.target,
      pending_message.publisher.id,
      pending_message.message
    ])
  end

  def get_handler_module(type) when type == "http", do: Http
  def get_handler_module(type) when type == "pubsub", do: Pubsub
end
