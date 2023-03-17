defmodule LiveFormsWeb.Calendar do
  use LiveFormsWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, date: Date.utc_today(), selected_days: [])}
  end

  def handle_event("next", _params, socket) do
    {:noreply, assign(socket, :date, next_month(socket.assigns.date))}
  end

  def handle_event("prev", _params, socket) do
    {:noreply, assign(socket, :date, prev_month(socket.assigns.date))}
  end

  def handle_event("select", %{"date" => date}, socket) do
    date_as_date = Date.from_iso8601!(date)
    {:noreply, assign(socket, :selected_days, Enum.uniq([date_as_date | socket.assigns.selected_days]))}
  end

  def handle_event("unselect", %{"date" => date}, socket) do
    date_as_date = Date.from_iso8601!(date)
    {:noreply, assign(socket, :selected_days, Enum.reject(socket.assigns.selected_days, &(&1 == date_as_date)))}
  end

  def next_month(date) do
    date
    |> Date.end_of_month()
    |> Date.add(1)
  end

  def prev_month(date) do
    date
    |> Date.beginning_of_month()
    |> Date.add(-1)
  end

  defp start_padding(date) do
    day =
      date
      |> Date.beginning_of_month()
      |> Date.day_of_week()

    if (day - 1) == 0, do: [], else: 1..(day - 1)
  end

  defp end_padding(date) do
    day =
      date
      |> Date.end_of_month()
      |> Date.day_of_week()

    if (7 - day) == 0, do: [], else: 1..(7 - day)
  end
end
