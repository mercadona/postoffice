# Postoffice
[![CircleCI](https://circleci.com/gh/lonamiaec/postoffice/tree/master.svg?style=svg)](https://circleci.com/gh/lonamiaec/postoffice/tree/master)

---
## What's postoffice?
We can think about postoffice as a real post office. You send `messages` to a `topic` and `publishers` send it to anyone interested in this topic. In case the receiver is not available, we'll try to deliver the message later.
It uses a pub/sub approach, so instead of handling receiver's addresses we use topics, and receivers must subscribe to them through `Publishers`.
A publisher is isolated from others and it handles itself its own pending messages



## Motivation
This project started as a solution to buffer messages in case some apps are deployed on-premise and could work with connectivity issues. Then it evolved to also offer a pub/sub mechanism.

## What's not Postoffice?
This is not designed to be realtime. We use `GenStage` to process pending messages. We create a process tree for each `Publisher`. It looks like an ETL, and it's refreshed each 10 seconds.

## Features
* Buffer messages in case receiver system is down or there is no connectivity for any reason.
* Deliver messages through:
  * Http.
  * Pub/Sub (GCloud).
* API to create topics/publishers.
* Web interface:
  * Manage topics/publishers.
  * Search messages to see when it was received and proccessed.
* Cluster nodes. Best effort to avoid sending messages more than once. (More info on clustering later)
* Endpoint to be used as health-check from k8s `/api/health`
## How to install it locally
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

## Clustering
Postoffice has been developed to be used forming a cluster. We use [libcluster](https://github.com/bitwalker/libcluster) under the hood to create the cluster. You can take a look at its documentation in case you want to tune settings.

## What's next?
Some desired features have been delayed until the first release:
* Set publishers as `recoverable`. This means any service sending messages to `Postoffice` will save messages that couldn't be delivered to us on their side, and expose an API so `Postoffice` will automatically consume those messages. API definition is still pending.
* Some code is duplicated in `Handlers` layer. Refactor to have just one handler module and N adapters.
* Be able to configure `max_demand` through environment variables.
* Provide a mechanism to run schema migrations.
* Do not try to create a k8s cluster by default, change how it's configured.
* Create docker images to make it easier to run Postoffice.
