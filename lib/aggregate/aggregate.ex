defmodule Benchmark do
  def measure(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end

defmodule DomainEngine.Aggregate do
  use GenServer
  require Logger

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

  def start_link(subdomain, aggregate_name, id, actor_id) do
    IO.puts "Starting aggregate link " <> actor_id
    GenServer.start_link(__MODULE__, {subdomain, aggregate_name, id, actor_id}, name: via_tuple(actor_id))
  end

  def via_tuple(actor_id), do: {:via, Horde.Registry, {DomainEngine.DomainEngineRegistry, actor_id}}

  def gen_actor_id(subdomain, aggregate_name, id), do: subdomain <> "-" <> aggregate_name <> "-" <> id


  def init({subdomain, aggregate_name, id, actor_id}) do
    {:ok, %{subdomain: subdomain, aggregate_name: aggregate_name, id: id, state: nil, current_version: 0}}
  end

  def handle_cast({:command, newState}, %{id: id, state: _state}) do
    IO.puts "HANDLE CAST"
    {:ok, response} = Finch.build(:get, DomainEngine.Application.domain_gateway_url()) |> Finch.request(FinchClient)
    IO.puts response.body
    {:noreply, %{id: id, state: newState}}
  end

  def handle_call({:get}, _from, state) do
    {:reply, state,state}
  end

end

# Horde.DynamicSupervisor.start_child(DomainEngine.DomainEngineSupervisor, {DomainEngine.Aggregate, [id: "123", subdomain: "auth", aggregate_name: "user"]})
# GenServer.cast({:via, Horde.Registry, {DomainEngine.DomainEngineRegistry, "auth-user-123"}}, {:command, 1})
# GenServer.call({:via, Horde.Registry, {DomainEngine.DomainEngineRegistry, "some3"}}, {:get})
# Horde.Registry.lookup(DomainEngine.DomainEngineRegistry, "auth-user-123")
# children = [
#   {DomainEngine.Aggregate, {1, 100}}
# ]



# children = [
#   worker(Registry, :unique, :id)
# ]

## TRUEEE
# Registry.start_link(keys: :unique, name: :id)
# DomainEngine.Aggregate.start_link("asd2",100)
# GenServer.cast({:via, Registry, {:id, "asd2"}}, {:command, 2})
# GenServer.call({:via, Registry, {:id, "asd2"}}, {:get})
# Registry.lookup(:id, "asd2")
# https://www.youtube.com/watch?v=VG8bBnOYj2g
# https://hexdocs.pm/elixir/1.15.0/Registry.html





# defmodule DomainEngine.SayHello do
#   use GenServer
#   require Logger

#   def child_spec(opts) do
#     name = Keyword.get(opts, :name, __MODULE__)

#     %{
#       id: "#{__MODULE__}_#{name}",
#       start: {__MODULE__, :start_link, [name]},
#       shutdown: 10_000,
#       restart: :transient
#     }
#   end

#   def start_link(name) do
#     IO.puts name
#     case GenServer.start_link(__MODULE__, [], name: via_tuple(name)) do
#       {:ok, pid} ->
#         {:ok, pid}

#       {:error, {:already_started, pid}} ->
#         Logger.info("already started at #{inspect(pid)}, returning :ignore")
#         :ignore
#     end
#   end

#   def init(_args) do
#     {:ok, nil}
#   end

#   def via_tuple(name), do: {:via, Horde.Registry, {DomainEngine.DomainEngineRegistry, name}}
# end


# receive do
#   message ->
#     case Mint.HTTP.stream(conn, message) do
#       :unknown -> IO.puts(message)
#       {:ok, conn, responses} -> IO.puts(responses)
#     end
# end
