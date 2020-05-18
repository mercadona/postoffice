defmodule Postoffice.PubSubIngester.Adapters.PubSub do
  @behaviour Postoffice.PubSubIngester.Adapters.Impl

  def get(conn, sub_name) do
    GoogleApi.PubSub.V1.Api.Projects.pubsub_projects_subscriptions_pull(
      conn,
      get_project_id(),
      sub_name,
      body: %GoogleApi.PubSub.V1.Model.PullRequest{
        maxMessages: get_max_messages()
      }
    )
  end

  def confirm(conn, ackIds, sub_name) do
    GoogleApi.PubSub.V1.Api.Projects.pubsub_projects_subscriptions_acknowledge(
      conn,
      get_project_id(),
      sub_name,
      body: %GoogleApi.PubSub.V1.Model.AcknowledgeRequest{
        ackIds: ackIds
      }
    )
  end

  def connect() do
    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
    GoogleApi.PubSub.V1.Connection.new(token.token)
  end

  defp get_project_id,
    do: Application.get_env(:postoffice, :gcloud_pubsub_project_id, 'test')

  defp get_max_messages,
    do: Application.get_env(:postoffice, :pubsub_max_messages, 10)
end
