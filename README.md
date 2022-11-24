# Postoffice
[![CircleCI](https://circleci.com/gh/mercadona/postoffice/tree/master.svg?style=svg)](https://circleci.com/gh/mercadona/postoffice/tree/master) [![Coverage Status](https://coveralls.io/repos/github/lonamiaec/postoffice/badge.svg?branch=master)](https://coveralls.io/github/lonamiaec/postoffice?branch=master)

---
## What's Postoffice?
We can think about Postoffice as a real post office. You send `messages` to a `topic` and `publishers` send them to anyone interested in this topic. In case the receiver is not available, Postoffice will try to deliver the message later.
Postoffice uses a pub/sub approach, so instead of handling receiver's addresses it uses topics, to which receivers must subscribe through `Publishers`.
A publisher is isolated from others and it handles itself its own pending messages.

## Motivation
This project started as a solution to buffer messages in case some apps are deployed on-premise and could suffer connectivity issues. Then it evolved to also offer a pub/sub mechanism.

## What's not Postoffice?
This is not designed to be realtime. Postoffice uses [GenStage](https://github.com/elixir-lang/gen_stage) to process pending messages, creating a process tree for each `Publisher`. It looks like an ETL, and it's refreshed every 10 seconds.

## Features
* Buffer messages in case the receiver system is down or there is no connectivity for some reason.
* Deliver messages through:
  * Http.
  * Pub/Sub (GCloud).
* API to create topics/publishers.
* Web interface:
  * Manage topics/publishers.
  * Search messages to see when it was received and processed.
* Cluster nodes. Best effort to avoid sending messages more than once. (More info on clustering later)
* Endpoint to be used as health-check from k8s `/api/health`

## API
We expose an API to enable projects to create the structure they need to work: topics, publishers and messages.
For both topics and publishers, if the resource already exist we return `409 Conflict`.
In case that another validation error happened, we return `400 bad request`

### Topics
Here we have a sample request to create a topic. All fields are required
```
POST /api/topics
{
  "name": "example-topic",
  "origin_host": sender_service.com
}
```
Attributes:
* _name_: topic name, it's what publishers will use to subscribe.
* _origin_host_: Host URL where messages for this topic will come from. This will used in a future feature to recover undelivered messages.

### Publishers
Publishers creation example. The only non required field is `from_now`
```
POST /api/publishers
{
  "active": True,
  "topic": "example-topic",
  "target": "http://myservice.com/examples",
  "type": "http/pubsub",
  "from_now": True
}
```
Attributes:
* _active_: if this publisher is active and must check and send pending messages or not.
* _topic_: from which topic this publisher should take messages.
* _target_: the endpoint where the post request with the message will be done.
* _type_: We now support two different types of publishers.
  * _http_: the messages are sent via POST request to a target url.
  * _pubsub_: messages are published to a target topic on GCloud Pub/Sub service.
* _from_now_: This param controls if you want to receive messages from this topic from now or in the other hand you're interested in the complete topic's messages.

### Messages
Message creation example. All fields are required
```
POST /api/messages
{
  "topic": topic,
  "payload": {},
  "attributes": {}
}
```
Attributes:
* _topic_: to which topic the message should be associated.
* _payload_: the message body.
* _attributes_: for pubsub publishers this attributes are added as GCloud Pub/Sub has this option. All attributes should be strings.

## How to install it locally
To start your Phoenix server:
  * `brew update`
  * `brew install elixir`
  * Create the following environmet variables in order to start the application:
    * `GOOGLE_APPLICATION_CREDENTIALS` with the absolute path to the pubsub credentials file.
    * `GCLOUD_PUBSUB_PROJECT_ID` with the project_id used.
    * `MAX_BULK_MESSAGES` with the max number of messages that postoffice is able to consume

  Note: There are some dummy credentials that can be used for local development
  ```
    $ export GOOGLE_APPLICATION_CREDENTIALS=`pwd`/config/dummy-credentials.json
    $ export GCLOUD_PUBSUB_PROJECT_ID=fake
    $ export MAX_BULK_MESSAGES=10
  ```
  
  * `mix local.hex`
  * `mix archive.install hex phx_new 1.4.11`
  * Install dependencies with `mix deps.get`
  * Run `docker-compose -f docker/docker-compose.yml up -d` to start a new postgres database
  * Create and migrate your database with `mix ecto.setup`
  * Execute `npm install` inside `assets/`
  * Start Phoenix endpoint with `mix phx.server`
Now you can visit [`localhost:4000`](http://localhost:4000) from your browser or run tests with `mix test`

## How to install it locally with docker
To start postoffice bundle with docker:
  * Build postoffice image `make build`
  * Start postoffice app with `make env-start` [1]. Now you can visit [`localhost:4001`](http://localhost:4001) from your browser 
  * Run test `make test`
  * Show logs with `make view-logs`

[1] _While `make env-start` you can execute `make view-logs` in other terminal to show what is happening_ 

## Environment variables

* `GOOGLE_APPLICATION_CREDENTIALS` is the Google Cloud Platform service account json path.
* `GCLOUD_PUBSUB_PROJECT_ID` is the Google Cloud Platform project where your PubSub topics/subscriptions are located.
* `MAX_BULK_MESSAGES` is the maximum number of messages that Postoffice would be able to instert in bulk.
* `CLEAN_MESSAGES_THRESHOLD` defines from what time you want to keep the historical data from the `sent_messages` table (in seconds)
* `CLEAN_MESSAGES_CRONTAB` defines when the Oban cronjob to clean historical data from the `sent_messages` table should be run.  Must be a valid crontab declaration.
* `CLUSTER_NAME` defines cluster name to diferentiate historical data in pubsub from diferent clusters
* `PUBSUB_HISTORICAL_TOPIC_NAME` defines the name of pubsub topic to send historical data. Defaul `postoffice-sent-messages`

## Clustering
Postoffice has been developed to be used forming a cluster. We use [libcluster](https://github.com/bitwalker/libcluster) under the hood to create the cluster. You can take a look at its documentation in case you want to tune settings.

## What's next?
Some desired features have been delayed until the first release:
* Be able to configure `max_demand` through environment variables.
* Provide a mechanism to run schema migrations.
* Do not try to create a k8s cluster by default, change how it's configured.
* Create docker images to make it easier to run Postoffice.
