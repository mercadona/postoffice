# Postoffice

To start your Phoenix server:
  * `brew update`
  * `brew install elixir`
  * Create the following environmet variables in order to start the application:
    * `GCLOUD_PUBSUB_CREDENTIALS_PATH` with the absolute path to the pubsub credentials file. We provide `config/dummy-credentials.json` to be able to start the app.
    * `GCLOUD_PUBSUB_PROJECT_ID` with the project_id used.
  * `mix local.hex`
  * `mix archive.install hex phx_new 1.4.11`
  * Install dependencies with `mix deps.get`
  * Inside `docker` directory, run `docker-compose up -d` to start a new postgres database
  * Create and migrate your database with `mix ecto.setup`
  * Execute `npm install` inside `assets/`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
