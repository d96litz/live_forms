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

    {
      :ok,
      assign(
        socket,
        users: users,
        form: form,
        sorted_by: :name,
        sort_dir: :asc,
        search: %{} |> to_form,
        query: ""
      )
    }
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    {:noreply, assign(socket, :form, user_params |> validate |> to_form)}
  end

  def handle_event("remove", %{"id" => user_id}, socket) do
    User
    |> Repo.get(user_id)
    |> Repo.delete()

    form =
      %User{}
      |> User.changeset(socket.assigns.form.source.changes)
      |> Map.put(:action, :validate)
      |> to_form

    socket = put_flash(socket, :info, "User removed")

    {:noreply, assign(socket, users: Repo.all(User), form: form)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case %User{} |> User.changeset(user_params) |> Repo.insert() do
      {:ok, _} ->
        socket = put_flash(socket, :info, "User created")

        {
          :noreply,
          assign(
            socket,
            users: Repo.all(User),
            form: user_params |> validate
          )
        }

      {:error, _} ->
        {:noreply, assign(socket, :form, user_params |> validate)}
    end
  end

  def handle_event("order", %{"by" => field}, socket) do
    field_atom = field |> String.to_existing_atom()

    new_sort_dir =
      if socket.assigns.sorted_by == field_atom do
        flip_sorting(socket.assigns.sort_dir)
      else
        socket.assigns.sort_dir
      end

    socket = assign(socket, sort_dir: new_sort_dir, sorted_by: field_atom)

    {:noreply, assign(socket, users: get_users(socket))}
  end

  def handle_event("search", %{"query" => query}, socket) do
    socket =
      socket
      |> assign(query: query)
      |> assign(users: socket |> get_users) # This needs to done after the query assign

    {:noreply, socket}
  end

  defp get_users(socket) do
    from(u in User,
      where:
        ilike(u.name, ^"%#{socket.assigns.query}%") or
          ilike(u.email, ^"%#{socket.assigns.query}%") or
          ilike(u.bio, ^"%#{socket.assigns.query}%"),
      order_by: [{^socket.assigns.sort_dir, ^socket.assigns.sorted_by}]
    )
    |> Repo.all()
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
