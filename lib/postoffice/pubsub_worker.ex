defmodule Postoffice.PubsubWorker do
  require Logger

  use Oban.Worker,
    queue: :pubsub,
    priority: 3,
    max_attempts: 100,
    tags: ["export"]

  alias Postoffice.Workers.Pubsub

  @impl Oban.Worker
  def perform(%Oban.Job{attempt: attempt, id: id, args: args}) when attempt == 99 do
    Logger.warn("Last retry for task", id: id, args: args)
    Pubsub.run(id, args)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{id: id, args: args}) do
    Pubsub.run(id, args)
  end
end
