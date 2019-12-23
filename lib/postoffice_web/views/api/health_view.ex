defmodule PostofficeWeb.Api.HealthView do
  use PostofficeWeb, :view

  def render("index.json", %{health_status: health_status}) do
    %{
      status: health_status
    }
  end
end
