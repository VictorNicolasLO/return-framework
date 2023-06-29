
defmodule DomainEngine.AggregateWritter do
  use GenServer

  # TODO Add child for supervisor horder
  def start_link(id, event) do
    GenServer.start_link(__MODULE__, {id, event}, name: {:via, :horde, {__MODULE__, id}})
  end

  def init({subdomain, aggregate_name, id}) do
    {:ok, %{subdomain: subdomain, aggregate_name: aggregate_name, id: id, current_version: 0, queue: :queue.new, unlock_map: %{} }}
  end

  # TODO check if writer exist in horde registry if not check if aggregate registry exist if it exist, send a call to recreate writter else recreate aggregate as well
  def enqueue_event(writer_id, event_data) do
    GenServer.cast(writer_id, {:enqueue_event, event_data})
  end



  # flow_id == flow-correlation_id
  def handle_cast({:enqueue_event, event_data}, state) do
    queue = :queue.in(event_data, state.queue)
    next_state = check_queue(%{state | queue: queue})
    {:noreply, next_state}
  end

  def handle_cast({:unlock, {causation_id}}, state) do
    next_unlock_map = Map.put(state.unlock_map, causation_id, true)
    next_state = check_queue(%{state | unlock_map: next_unlock_map})
    {:noreply, next_state}
  end

  defp check_queue(state) do
    queue = state.queue
    if :queue.is_empty(queue) do
      state
    else
      {event_id, correlation_id, causation_id, version, event_type, payload, event_time, requires_previous_commit} = :queue.head(queue)
      if not requires_previous_commit do
        {_value, next_queue} = :queue.out(queue)
        save_event({event_id, correlation_id, causation_id, version, event_type, payload, event_time, requires_previous_commit}, state)
        check_queue(%{state | queue: next_queue})
      else
        if state.unlock_map[correlation_id] do
          {_value, next_queue} = :queue.out(queue)
          next_unlock_map = Map.delete(state.unlock_map, causation_id)
          save_event({event_id, correlation_id, causation_id, version, event_type, payload, event_time, requires_previous_commit}, state)
          check_queue(%{state | queue: next_queue, unlock_map: next_unlock_map})
        else
          state
        end
      end
    end
  end

  defp save_event({event_id, correlation_id, causation_id, version, event_type, payload, event_time, requires_previous_commit}, state) do
    append_event_statement = "INSERT INTO domain.aggregates (event_id, aggregate_name, domain_name, version, event_time, event_type, correlation_id, causation_id, payload) VALUES (:event_id, :aggregate_name, :domain_name, :version, :event_time, :event_type, :correlation_id, :causation_id, :payload);"
    {:ok, %Xandra.Void{}} = Xandra.execute(XandraConnection, append_event_statement, params = %{
      "event_id" => {"uuid", event_id},
      "aggregate_name" => {"text", state.aggregate_name},
      "domain_name" => {"text", state.domain_name},
      "version" => {"bigint", version},
      "event_time" => {"timestamp", event_time},
      "event_type" => {"text", event_type},
      "correlation_id" => {"uuid", correlation_id},
      "causation_id" => {"uuid", causation_id},
      "payload" => {"map<text, text>", payload}
    })

    # TODO notify to flow writter to save things -> ex. FlowWriter.unlock(event_id)
  end

  defp send_message() do
    ""
  end

end
