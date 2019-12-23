defmodule PostofficeWeb.StatsLive do
  use Phoenix.LiveView

  alias Postoffice
  alias Postoffice.Messaging

  def render(assigns) do
    ~L"""
    <div class="row">
      <div class="col-md-4 col-sm-6 col-xs-12">
        <div class="info-box bg-info">
          <span class="info-box-icon"><i class="fa fa-bullhorn"></i></span>

          <div class="info-box-content">
            <span class="info-box-text">Topics</span>
            <span class="info-box-number"><%= @topics %></span>
          </div>
        </div>
      </div>
      <div class="col-md-4 col-sm-6 col-xs-12">
        <div class="info-box bg-yellow">
          <span class="info-box-icon"><i class="fa fa-cogs"></i></span>

          <div class="info-box-content">
            <span class="info-box-text">Http Publishers</span>
            <span class="info-box-number"><%= @http_publishers %></span>
          </div>
        </div>
      </div>
      <div class="col-md-4 col-sm-6 col-xs-12">
        <div class="info-box bg-yellow">
          <span class="info-box-icon"><i class="fa fa-cloud-upload"></i></span>
          <div class="info-box-content">
            <span class="info-box-text">PubSub Publishers</span>
            <span class="info-box-number"><%= @pubsub_publishers %></span>
          </div>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-md-4 col-sm-6 col-xs-12">
        <div class="info-box bg-info">
          <span class="info-box-icon"><i class="fa fa-envelope"></i></span>

          <div class="info-box-content">
            <span class="info-box-text">Messages</span>
            <span class="info-box-number"><%= @messages %></span>
          </div>
        </div>
      </div>
      <div class="col-md-4 col-sm-6 col-xs-12">
        <div class="info-box bg-green">
          <span class="info-box-icon"><i class="fa fa-envelope"></i></span>

          <div class="info-box-content">
            <span class="info-box-text">Messages sent</span>
            <span class="info-box-number"><%= @messages_sent %></span>
          </div>
        </div>
      </div>
      <div class="col-md-4 col-sm-6 col-xs-12">
        <div class="info-box bg-red">
          <span class="info-box-icon"><i class="fa fa-envelope"></i></span>

          <div class="info-box-content">
            <span class="info-box-text">Messages failed</span>
            <span class="info-box-number"><%= @messages_failed %></span>
          </div>
        </div>
      </div>
    </div>

    """
  end

  def mount(_session, socket) do
    if connected?(socket), do: :timer.send_interval(300, self(), :tick)

    {:ok, put_info(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, put_info(socket)}
  end

  defp put_info(socket) do
    assign(socket,
      topics: Postoffice.count_topics(),
      messages: Postoffice.count_received_messages(),
      messages_sent: Postoffice.count_sent_messages(),
      messages_failed: Postoffice.count_failed_messages(),
      http_publishers: Postoffice.count_http_publishers(),
      pubsub_publishers: Postoffice.count_pubsub_publishers(),
      last_messages: []
    )
  end
end
