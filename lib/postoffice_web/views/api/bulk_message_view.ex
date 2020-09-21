defmodule PostofficeWeb.Api.BulkMessageView do
  use PostofficeWeb, :view
  alias PostofficeWeb.Api.MessageView

  def render("show.json", %{message_ids: message_ids}) do
    %{result: message_ids}
  end

  def render("error.json", %{changeset: changeset}) do
    %{data: render_one(changeset, MessageView, "error.json")}
  end

  def render("error.json", %{error: error}) do
    %{data: %{errors: error}}
  end

  def render("error.json", %{message: message_changeset}) do
    %{
      errors: Ecto.Changeset.traverse_errors(message_changeset, &translate_error/1)
    }
  end
end
