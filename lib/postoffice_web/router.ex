defmodule PostofficeWeb.Router do
  use PostofficeWeb, :router

  import Phoenix.LiveDashboard.Router

  alias Api.MessageController, as: ApiMessageController
  alias Api.BulkMessageController, as: ApiBulkMessageController
  alias Api.TopicController, as: ApiTopicController
  alias Api.PublisherController, as: ApiPublisherController
  alias Api.HealthController, as: ApiHealthController
  alias MessageController, as: MessageController
  alias IndexController

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PostofficeWeb do
    pipe_through :browser

    get "/", IndexController, :index, as: :dashboard

    resources "/topics", TopicController, only: [:index, :new, :create]

    resources "/publishers", PublisherController, only: [:index, :new, :create, :edit, :update]

    resources "/messages", MessageController, only: [:index, :show]

    live_dashboard "/dashboard"
  end

  scope "/api", PostofficeWeb, as: :api do
    pipe_through :api
    resources "/messages", ApiMessageController, only: [:create, :show]
    resources "/bulk_messages", ApiBulkMessageController, only: [:create, :show]
    resources "/topics", ApiTopicController, only: [:create, :show]
    resources "/publishers", ApiPublisherController, only: [:create]
    resources "/health", ApiHealthController, only: [:index]
  end
end
