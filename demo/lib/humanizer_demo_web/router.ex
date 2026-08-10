defmodule HumanizerDemoWeb.Router do
  use HumanizerDemoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HumanizerDemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HumanizerDemoWeb do
    get "/health", HealthController, :show
  end

  scope "/", HumanizerDemoWeb do
    pipe_through :browser

    live "/", PlaygroundLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", HumanizerDemoWeb do
  #   pipe_through :api
  # end
end
