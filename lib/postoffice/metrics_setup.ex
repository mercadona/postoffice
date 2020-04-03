defmodule Postoffice.MetricsSetup do
  def setup do
    PostofficeWeb.Metrics.Phoenix.setup()
    PostofficeWeb.Metrics.Exporter.setup()
    PostofficeWeb.Metrics.Ecto.setup()
  end
end
