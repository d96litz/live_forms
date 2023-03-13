defmodule LiveFormsWeb.UserList do
  use LiveFormsWeb, :live_view
  alias LiveForms.{Repo, User}
  import Ecto.Query

  @spec mount(any, map, map) :: {:ok, map}
  def mount(_params, %{}, socket) do
    users = Repo.all(User)

    form =
      User.changeset(%User{}, %{})
      |> to_form

    {:ok, assign(socket, users: users, form: form, sorted_by: "name", sort_dir: :asc)}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    {:noreply, assign(socket, :form, user_params |> validate |> to_form)}
  end

  def handle_event("remove", %{"value" => user_id}, socket) do
    User
    |> Repo.get(user_id)
    |> Repo.delete()

    form =
      %User{}
      |> User.changeset(socket.assigns.form.source.changes)
      |> Map.put(:action, :validate)
      |> to_form

    {:noreply, assign(socket, users: Repo.all(User), form: form)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case %User{} |> User.changeset(user_params) |> Repo.insert() do
      {:ok, _} ->
        {
          :noreply,
          assign(
            socket,
            users: Repo.all(User),
            form: user_params |> validate
          )
        }

      {:error, _} ->
        {:noreply, assign(socket, :form, user_params |> validate |> to_form)}
    end
  end

  def handle_event("order", %{"by" => field}, socket) do
    IO.inspect(socket.assigns.sort_dir)

    new_sort_dir =
      if socket.assigns.sorted_by == field do
        flip_sorting(socket.assigns.sort_dir)
      else
        socket.assigns.sort_dir
      end

    users =
      from(u in User,
        order_by: [{^new_sort_dir, ^String.to_existing_atom(field)}]
      )

    {
      :noreply,
      assign(
        socket,
        users: Repo.all(users),
        sorted_by: field,
        sort_dir: new_sort_dir
      )
    }
  end

  defp validate(params) do
    User.changeset(%User{}, params)
    |> Map.put(:action, :validate)
    |> to_form
  end

  defp flip_sorting(:asc) do
    :desc
  end

  defp flip_sorting(:desc) do
    :asc
  end
end
