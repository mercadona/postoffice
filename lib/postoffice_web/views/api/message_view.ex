defmodule PostofficeWeb.Api.MessageView do
  use PostofficeWeb, :view
  alias PostofficeWeb.Api.MessageView

  def render("index.json", %{messages: messages}) do
    %{data: render_many(messages, MessageView, "message.json")}
  end

  def render("show.json", %{message: message}) do
    %{data: render_one(message, MessageView, "message.json")}
  end

  def render("message.json", %{message: message}) do
    %{
      public_id: message.public_id
    }
  end
end
