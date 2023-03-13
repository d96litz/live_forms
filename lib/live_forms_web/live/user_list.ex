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
        search: %{} |> to_form
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

    socket = put_flash(socket, :info, "User removed successfully")

    {:noreply, assign(socket, users: Repo.all(User), form: form)}
  end

  def handle_event("edit", %{"id" => user_id}, socket) do
    user = Repo.get(User, user_id)

    form =
      user
      |> User.changeset(%{})
      |> Map.put(:action, :save)
      |> to_form

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case %User{} |> User.changeset(user_params) |> Repo.insert do
      {:ok, _} ->
        socket = put_flash(socket, :info, "User created successfully")
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
    IO.inspect(socket.assigns.sorted_by)

    field_atom = field |> String.to_existing_atom()

    new_sort_dir =
      if socket.assigns.sorted_by == field_atom do
        flip_sorting(socket.assigns.sort_dir)
      else
        socket.assigns.sort_dir
      end

    users =
      from(u in User,
        order_by: [{^new_sort_dir, ^field_atom}]
      )

    {
      :noreply,
      assign(
        socket,
        users: Repo.all(users),
        sorted_by: field_atom,
        sort_dir: new_sort_dir
      )
    }
  end

  def handle_event("search", %{"query" => query}, socket) do
    users =
      from(u in User,
        where:
          ilike(u.name, ^"%#{query}%") or
            ilike(u.email, ^"%#{query}%") or
            ilike(u.bio, ^"%#{query}%"),
        order_by: [{^socket.assigns.sort_dir, ^socket.assigns.sorted_by}]
      )

    {:noreply, assign(socket, users: Repo.all(users))}
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
