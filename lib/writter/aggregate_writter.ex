defmodule DomainEngine.AggregateWritter do
  use GenServer
  import DomainEngine.Actor

  def child_spec(opts) do
    subdomain = Keyword.get(opts, :subdomain, __MODULE__)
    aggregate_name = Keyword.get(opts, :aggregate_name, __MODULE__)
    id = Keyword.get(opts, :id, __MODULE__)
    actor_id = gen_actor_id(subdomain, aggregate_name, id)

    %{
      id: "#{__MODULE__}_#{actor_id}",
      start: {__MODULE__, :start_link, [subdomain, aggregate_name, id, actor_id]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  # TODO Add child for supervisor horder
  def start_link(subdomain, aggregate_name, id, actor_id) do
    IO.puts("Starting aggregate link " <> actor_id)

    GenServer.start_link(__MODULE__, {subdomain, aggregate_name, id, actor_id},
      name: via_tuple(actor_id)
    )
  end

  def gen_actor_id(subdomain, aggregate_name, id),
    do: subdomain <> "-" <> aggregate_name <> "-" <> id <> "-writter"

  # Ensure allways the aggregate writter is created, this follows the version and also ensure everytime a record i saved it changes the record as well
  def init({subdomain, aggregate_name, id, actor_id}) do
    {:ok,
     %{
       subdomain: subdomain,
       aggregate_name: aggregate_name,
       id: id,
       state: nil,
       current_version: 0,
       actor_id: actor_id
     }}
  end

  # TODO check if writer exist in horde registry if not check if aggregate registry exist if it exist, send a call to recreate writter else recreate aggregate as well
  def enqueue_event({subdomain, aggregate_name, id}, event_data) do
    cast_if_exists({subdomain, aggregate_name, id}, {:enqueue_event, event_data})
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

  def cast_if_exists({subdomain, aggregate_name, id}, message) do
    actor_id = gen_actor_id(subdomain, aggregate_name, id)
    via = via_tuple(actor_id)

    if exists?(actor_id) do
      GenServer.cast(via, message)
    else
      Horde.DynamicSupervisor.start_child(
        DomainEngine.DomainEngineSupervisor,
        {DomainEngine.AggregateWritter,
         [id: id, subdomain: subdomain, aggregate_name: aggregate_name]}
      )

      GenServer.cast(via, message)
    end
  end

  defp check_queue(state) do
    # TODO validate the next message is saved follows the version, else throws error and reset everything because of collission
    queue = state.queue

    if :queue.is_empty(queue) do
      state
    else
      {aggregate_id, causation_id, version, event_type, payload, event_time,
       requires_previous_commit} = :queue.head(queue)

      if not requires_previous_commit do
        {_value, next_queue} = :queue.out(queue)

        save_event(
          {aggregate_id, causation_id, version, event_type, payload, event_time,
           requires_previous_commit},
          state
        )

        check_queue(%{state | queue: next_queue})
      else
        if state.unlock_map[causation_id] do
          {_value, next_queue} = :queue.out(queue)
          next_unlock_map = Map.delete(state.unlock_map, causation_id)

          save_event(
            {aggregate_id, causation_id, version, event_type, payload, event_time,
             requires_previous_commit},
            state
          )

          check_queue(%{state | queue: next_queue, unlock_map: next_unlock_map})
        else
          state
        end
      end
    end
  end

  defp save_event(
         {aggregate_id, causation_id, version, event_type, payload, event_time,
          _requires_previous_commit},
         state
       ) do
    append_event_statement =
      "INSERT INTO domain.aggregates (domain_name, aggregate_name, aggregate_id, version, causation_id, event_time, event_type, payload) VALUES (?, ?, ?, ?, ?, ?, ?, ?) IF NOT EXISTS;"

    {:ok, page} =
      Xandra.execute(
        XandraConnection,
        append_event_statement,
        [
          {"text", state.domain_name},
          {"text", state.aggregate_name},
          {"uuid", aggregate_id},
          {"bigint", version},
          {"tuple<text, text, uuid, bigint>", causation_id},
          {"timestamp", event_time},
          {"text", event_type},
          {"map<text, text>", payload}
        ]
      )

    [%{"[applied]" => applied}] = Enum.to_list(page)

    if applied do
      send_message(causation_id)
      # TODO notify to flow writter to save things -> ex. FlowWriter.unlock(event_id)
    else
      # TODO throw error and reset everything
    end
  end

  defp send_message(event_id) do
    Flowwriter.unlock(event_id)
  end
end

# {:ok, page} =
#   Xandra.execute(
#     XandraConnection,
#     append_event_statement,
#     [
#       {"text", "domain_name"},
#       {"text", "aggregate_name"},
#       {"uuid", "123e4567-e89b-12d3-a456-426614174001"},
#       {"bigint", 7},
#       {"tuple<text, text, uuid, bigint>",
#        {"causation_id", "aggregate_id", "123e4567-e89b-12d3-a456-426614174001", 1}},
#       {"timestamp", :os.system_time(:millisecond)},
#       {"text", "event_type"},
#       {"map<text, text>", %{"payload" => "payload"}}
#     ]
#   )
