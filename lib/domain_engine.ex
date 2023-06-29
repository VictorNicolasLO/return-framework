# defmodule DomainEngine do
#   @moduledoc """
#   Documentation for DomainEngine.
#   """

#   @doc """
#   Hello world.

#   ## Examples

#       iex> DomainEngine.hello()
#       :world

#   """
#   def hello do
#     IO.puts(:ok2)
#     :world
#   end
# end


# iex --erl '+P 134217727 +A 8' -S mix
# iex --name node1@127.0.0.1 --cookie asdf -S mix
# Node.connect(:"node2@127.0.0.1")

defmodule DomainEngine.Application do
  use Application

  @initial_domain_gateway_url "http://0.0.0.0:50051"
  def domain_gateway_url, do: @initial_domain_gateway_url


  def start(_type, _args) do
    IO.puts "INIT"

    children = [
      {Finch, name: FinchClient},
      {Xandra, name: XandraConnection, nodes: ["127.0.0.1:9042"], keyspace: "domain"},
      {Horde.Registry, [name: DomainEngine.DomainEngineRegistry, keys: :unique, members: :auto]},
      {Horde.DynamicSupervisor, [name: DomainEngine.DomainEngineSupervisor, strategy: :one_for_one, members: :auto]},

    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
# DomainEngine.Application.start(:type,:args)
# Horde.DynamicSupervisor.start_child(HelloWorld.HelloSupervisor, {HelloWorld.SayHello, [name: "some"]})
