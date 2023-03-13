defmodule LiveForms.Repo do
  use Ecto.Repo,
    otp_app: :live_forms,
    adapter: Ecto.Adapters.Postgres
end
