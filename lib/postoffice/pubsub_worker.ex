defmodule Postoffice.PubsubWorker do
  require Logger

  use Oban.Worker,
    queue: :pubsub,
    priority: 3,
    max_attempts: 100,
    tags: ["export"]

  alias Postoffice.Workers.Pubsub

  @impl Oban.Worker
  def perform(%Oban.Job{id: id, args: args}) do
    Pubsub.run(id, args)
  end
end
