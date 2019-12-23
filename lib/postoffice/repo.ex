defmodule Postoffice.Repo do
  use Ecto.Repo,
    otp_app: :postoffice,
    adapter: Ecto.Adapters.Postgres
end
