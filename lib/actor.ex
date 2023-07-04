defmodule DomainEngine.Actor do
  def exists?(actor_id) do
    case Horde.Registry.lookup(DomainEngine.DomainEngineRegistry, actor_id) do
      [] -> false
      _ -> true
    end
  end

  def via_tuple(actor_id),
    do: {:via, Horde.Registry, {DomainEngine.DomainEngineRegistry, actor_id}}
end
