defmodule Postoffice.Adapters.Pubsub do
  @moduledoc false
  require Logger

  @behaviour Postoffice.Adapters.Impl

  @impl true
  def publish(publisher, pending_messages) do
    Logger.info("Publishing PubSub message to #{publisher.target}")

    # Authenticate
    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
    Logger.info("successfully generated token for pubsub")
    conn = GoogleApi.PubSub.V1.Connection.new(token.token)

    request = %GoogleApi.PubSub.V1.Model.PublishRequest{
      messages: generate_messages(pending_messages)
    }

    # Make the API request.
    GoogleApi.PubSub.V1.Api.Projects.pubsub_projects_topics_publish(
      conn,
      Application.get_env(:postoffice, :pubsub_project_name),
      publisher.target,
      body: request
    )
  end

  defp generate_messages(pending_messages) do
    pending_messages
    |> Enum.map(fn message ->
      %GoogleApi.PubSub.V1.Model.PubsubMessage{
        data: Base.encode64(Poison.encode!(message.payload)),
        attributes: message.attributes
      }
    end)
  end
end
