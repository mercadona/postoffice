defmodule Postoffice.Adapters.Pubsub do
  @moduledoc false
  require Logger

  @behaviour Postoffice.Adapters.Impl

  @impl true
  def publish(endpoint, message) do
    Logger.info("Publishing PubSub message to #{endpoint}")
    %{payload: payload, attributes: attributes} = message
    # Authenticate
    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
    Logger.info("successfully generated token for pubsub")
    conn = GoogleApi.PubSub.V1.Connection.new(token.token)

    request = %GoogleApi.PubSub.V1.Model.PublishRequest{
      messages: [
        %GoogleApi.PubSub.V1.Model.PubsubMessage{
          data: Base.encode64(Poison.encode!(payload)),
          attributes: attributes
        }
      ]
    }

    # Make the API request.
    GoogleApi.PubSub.V1.Api.Projects.pubsub_projects_topics_publish(
      conn,
      Application.get_env(:postoffice, :pubsub_project_name),
      endpoint,
      body: request
    )
  end
end
