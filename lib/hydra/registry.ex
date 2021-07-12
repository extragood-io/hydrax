defmodule Hydra.Registry do
  @moduledoc """
  A PID registry for use across nodes in a cluster.
  """

  use Horde.Registry
  import Ex2ms

  def start_link(arg), do: Horde.Registry.start_link(__MODULE__, arg, name: __MODULE__)

  def keys(pid), do: Horde.Registry.keys(__MODULE__, pid)
  def lookup(key), do: Horde.Registry.lookup(__MODULE__, key)

  @impl true
  def init(arg) do
    [keys: :unique, members: :auto]
    |> Keyword.merge(arg)
    |> Horde.Registry.init()
  end

  def pid_name(flow, stage) do
    {:via, Horde.Registry, {__MODULE__, {flow, stage}}}
  end

  @doc """
  Takes a registered name in the form of a :via tuple and unwraps it to return the key.
  """
  def unwrap_pid_name({:via, Horde.Registry, {__MODULE__, name}}), do: name
  def unwrap_pid_name(_), do: nil

  def get_all() do
    selector = fun do {key, pid, _} -> {key, pid} end
    Horde.Registry.select(__MODULE__, selector)
  end

  @doc """
  Remove the given key from the registry.
  """
  def unregister(name = {:via, _, _}), do: name |> unwrap_pid_name() |> unregister()
  def unregister(name), do: Horde.Registry.unregister(__MODULE__, name)

  @doc """
  Lookup all PIDs associated with the given flow id.
  """
  def lookup_flow(id) do
    selector = fun do {{flow_id, stage}, pid, _} when flow_id == ^id -> {{flow_id, stage}, pid} end
    Horde.Registry.select(__MODULE__, selector)
  end

  @doc """
  Lookup the PIDs associated with the given flow id and stage name.
  """
  def lookup_flow(id, stage) do
    selector = fun do
      {{flow_id, stage_id}, pid, _} when flow_id == ^id and stage_id == ^stage ->
        pid
    end
    Horde.Registry.select(__MODULE__, selector)
  end
end
