defmodule HumanizerDemoWeb.HealthController do
  use HumanizerDemoWeb, :controller

  def show(conn, _params), do: text(conn, "ok\n")
end
