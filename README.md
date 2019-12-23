# Postoffice

To start your Phoenix server:
  * `brew update`
  * `brew install elixir`
  * Create an environment variable called `GCLOUD_PUBSUB_CREDENTIALS_PATH` with the absolute path to the `config/dummy-credentials.json` file
  * `mix local.hex`
  * `mix archive.install hex phx_new 1.4.11`
  * Install dependencies with `mix deps.get`
  * Inside `docker` directory, run `docker-compose up -d` to start a new postgres database
  * Create and migrate your database with `mix ecto.setup`
  * Execute `npm install` inside `assets/`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
