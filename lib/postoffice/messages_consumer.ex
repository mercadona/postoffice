defmodule Postoffice.MessagesConsumer do
  require Logger

  alias __MODULE__
  alias Postoffice.Handlers.Http
  alias Postoffice.Handlers.Pubsub

  def start_link(%{publisher: publisher, message: message}) do
    Task.start_link(MessagesConsumer.get_handler_module(publisher.type), :run, [
      publisher,
      message
    ])
  end

  def get_handler_module(type) when type == "http", do: Http
  def get_handler_module(type) when type == "pubsub", do: Pubsub
end
