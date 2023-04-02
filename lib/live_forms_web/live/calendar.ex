defmodule LiveFormsWeb.Calendar do
  use LiveFormsWeb, :live_view
  alias LiveForms.{Repo, Event}
  import Ecto.Query

  def mount(_params, _session, socket) do
    {
      :ok,
      assign(
        socket,
        date: Date.utc_today(),
        selected_days: [],
        first_date: nil,
        second_date: nil,
        event: nil,
        events: events_for_month(Date.utc_today())
      )
    }
  end

  def handle_event("next", _params, socket) do
    new_date = next_month(socket.assigns.date)
    events = events_for_month(new_date)
    {:noreply, assign(socket, date: new_date, events: events)}
  end

  def handle_event("prev", _params, socket) do
    new_date = prev_month(socket.assigns.date)
    events = events_for_month(new_date)
    {:noreply, assign(socket, date: new_date, events: events)}
  end

  def handle_event("select_first_date", %{"first_date" => first_date}, socket) do
    first_date_as_date = Date.from_iso8601!(first_date)
    {:noreply, assign(socket, :first_date, first_date_as_date)}
  end

  def handle_event("select_second_date", %{"second_date" => second_date}, socket) do
    IO.inspect(second_date)
    second_date_as_date = Date.from_iso8601!(second_date)
    socket = assign(socket, :second_date, second_date_as_date)
    handle_event("date_set", %{}, socket)
  end

  def handle_event("select_day", %{"day" => day}, socket) do
    day_as_date = Date.from_iso8601!(day)
    socket = assign(socket, first_date: day_as_date, second_date: day_as_date)
    handle_event("date_set", %{}, socket)
  end

  # Builds an event form
  def handle_event("date_set", _, socket) do
    smaller_date = min(socket.assigns.first_date, socket.assigns.second_date)
    bigger_date = max(socket.assigns.first_date, socket.assigns.second_date)

    {:noreply,
     assign(
       socket,
       :event,
       %Event{}
       |> Event.changeset(%{
         "start_date" => smaller_date,
         "end_date" => bigger_date
       })
       |> to_form
     )}
  end

  def handle_event("change", %{"event" => event_params}, socket) do
    new_first_date =
      case Date.from_iso8601(event_params["start_date"]) do
        {:error, _} -> socket.assigns.first_date
        {:ok, date} -> date
      end

    new_second_date =
      case Date.from_iso8601(event_params["end_date"] || event_params["start_date"]) do
        {:error, _} -> socket.assigns.second_date
        {:ok, date} -> date
      end

    {:noreply,
     assign(
       socket,
       event: %Event{} |> Event.changeset(event_params) |> Map.put(:action, :validate) |> to_form,
       first_date: new_first_date,
       second_date: new_second_date
     )}
  end

  def handle_event("save_event", %{"event" => event_params}, socket) do
    case %Event{} |> Event.changeset(event_params) |> Repo.insert() do
      {:ok, new_event} ->
        {:noreply, assign(socket, event: nil, events: [new_event | socket.assigns.events])}

      {:error, changeset} ->
        {:noreply, assign(socket, :event, changeset |> to_form)}
    end
  end

  def handle_event("delete_event", %{"id" => event_id}, socket) do
    event = Repo.get!(Event, event_id)
    Repo.delete!(event)
    {:noreply, assign(socket, event: nil, events: socket.assigns.events -- [event])}
  end

  defp cell_color(date, first_selected, second_selected, events) do
    if date == Date.utc_today() do
      "bg-green-500"
    else
      case {
        is_between_dates?(date, first_selected, second_selected),
        Enum.any?(events, &is_between_dates?(date, &1.start_date, &1.end_date))
      } do
        {true, true} -> "bg-orange-500"
        {true, false} -> "bg-red-500"
        {false, true} -> "bg-yellow-500"
        {false, false} -> "bg-white"
      end
    end
  end

  defp events_for_date(date, events) do
    events
    |> Enum.filter(&is_between_dates?(date, &1.start_date, &1.end_date))
    |> Enum.take(4)
  end

  defp events_for_month(date) do
    # Get all events where start and end date intersect with the current month
    beginning_of_month = date |> Date.beginning_of_month()
    end_of_month = date |> Date.end_of_month()

    Repo.all(
      from e in Event,
        where: e.start_date <= ^end_of_month and e.end_date >= ^beginning_of_month,
        order_by: [asc: e.id]
    )
  end

  defp is_between_dates?(_, nil, _), do: false
  defp is_between_dates?(_, _, nil), do: false

  defp is_between_dates?(date, first_date, second_date) do
    Enum.member?(Date.range(first_date, second_date), date)
  end

  defp next_month(date) do
    date
    |> Date.end_of_month()
    |> Date.add(1)
  end

  defp prev_month(date) do
    date
    |> Date.beginning_of_month()
    |> Date.add(-1)
  end

  defp start_padding(date) do
    day =
      date
      |> Date.beginning_of_month()
      |> Date.day_of_week()

    if day - 1 == 0, do: [], else: 1..(day - 1)
  end

  defp end_padding(date) do
    day =
      date
      |> Date.end_of_month()
      |> Date.day_of_week()

    if 7 - day == 0, do: [], else: 1..(7 - day)
  end
end
