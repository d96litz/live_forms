defmodule LiveForms.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LiveFormsWeb.Telemetry,
      # Start the Ecto repository
      LiveForms.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: LiveForms.PubSub},
      # Start Finch
      {Finch, name: LiveForms.Finch},
      # Start the Endpoint (http/https)
      LiveFormsWeb.Endpoint
      # Start a worker by calling: LiveForms.Worker.start_link(arg)
      # {LiveForms.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveForms.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveFormsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
