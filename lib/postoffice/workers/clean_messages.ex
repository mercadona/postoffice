defmodule Postoffice.Workers.CleanMessages do
  use Oban.Worker

  alias Postoffice.HistoricalData


  @impl Oban.Worker
  def perform(_job) do
    HistoricalData.clean_sent_messages()

    :ok
  end
end
