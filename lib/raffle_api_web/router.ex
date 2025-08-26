defmodule RaffleApiWeb.Router do
  use RaffleApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", RaffleApiWeb do
    pipe_through :api

    resources "/users", UserController, only: [:create, :show]
    resources "/raffles", RaffleController, only: [:create, :show]

    post "/raffles/:id/join", RaffleJoinController, :join
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:raffle_api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard",
        metrics: RaffleApiWeb.Telemetry,
        ecto_repos: [RaffleApi.Repo]
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
