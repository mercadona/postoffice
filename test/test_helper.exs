ExUnit.start(trace: true)
Ecto.Adapters.SQL.Sandbox.mode(Postoffice.Repo, :manual)

Mox.defmock(Postoffice.Adapters.HttpMock, for: Postoffice.Adapters.Impl)
Mox.defmock(Postoffice.Adapters.PubsubMock, for: Postoffice.Adapters.Impl)

Application.put_env(
  :postoffice,
  :http_consumer_impl,
  Postoffice.Adapters.HttpMock
)

Application.put_env(
  :postoffice,
  :pubsub_consumer_impl,
  Postoffice.Adapters.PubsubMock
)
