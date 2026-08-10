defmodule HumanizerDemoWeb.HealthControllerTest do
  use HumanizerDemoWeb.ConnCase, async: true

  test "GET /health returns a plain readiness response", %{conn: conn} do
    conn = get(conn, ~p"/health")

    assert response(conn, 200) == "ok\n"
    assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]
    assert get_resp_header(conn, "set-cookie") == []
  end
end
