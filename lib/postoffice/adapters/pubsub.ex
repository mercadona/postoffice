defmodule Postoffice.Adapters.Pubsub do
  @moduledoc false
  require Logger

  @behaviour Postoffice.Adapters.Impl

  @impl true
  def publish(
        id,
        %{
          "attributes" => attributes,
          "consumer_id" => consumer_id,
          "payload" => payload,
          "target" => target
        } = _args
      ) do
    Logger.info("Publishing PubSub message to #{target}", id: id, publisher_id: consumer_id)

    # Make the API request.
    GoogleApi.PubSub.V1.Api.Projects.pubsub_projects_topics_publish(
      GoogleApi.PubSub.V1.Connection.new(get_token()),
      Application.get_env(:postoffice, :pubsub_project_name),
      target,
      body: %GoogleApi.PubSub.V1.Model.PublishRequest{
        messages: [
          %GoogleApi.PubSub.V1.Model.PubsubMessage{
            data: Base.encode64(Poison.encode!(payload)),
            attributes: attributes
          }
        ]
      }
    )
  end

  defp get_token() do
    case Cachex.get(:pubsub_token, "token") do
      {:ok, nil} ->
        # Authenticate
        {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
        Logger.info("successfully generated token for pubsub")
        Cachex.put(:pubsub_token, "token", token.token, ttl: :timer.seconds(60 * 59))
        token.token

      {:ok, value} ->
        Logger.info("Using PubSub token from cache")
        value
    end
  end
end
