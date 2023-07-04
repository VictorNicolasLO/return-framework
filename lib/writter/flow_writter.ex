defmodule DomainEngine.FlowWritter do
  use GenServer

  def init(init_arg) do
    {:ok, init_arg}
  end

  def unlock(flow_id) do
    GenServer.cast(flow_id, {:unlock, {flow_id}})
  end

  def start_link(id, event) do
    GenServer.start_link(__MODULE__, {id, event}, name: {:via, :horde, {__MODULE__, id}})
  end

  # def unlock(flow_id) do
  #   GenServer.cast(flow_id, {:unlock, {flow_id}})
  # end

  # def start_link(id, event) do
  #   GenServer.start_link(__MODULE__, {id, event}, name: {:via, :horde, {__MODULE__, id}})
  # end
end
