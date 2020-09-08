defmodule Postoffice.HttpWorker do
  require Logger

  use Oban.Worker,
    queue: :http,
    priority: 0,
    max_attempts: 100,
    tags: ["hive"]

  alias Postoffice.Workers.Http

  @impl Oban.Worker
  def perform(%Oban.Job{attempt: attempt, id: id, args: args}) when attempt == 100 do
    Logger.warn("Last retry for task", id: id, args: args)
    Http.run(id, args)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{id: id, args: args}) do
    Http.run(id, args)
  end
end
