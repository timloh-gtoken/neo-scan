defmodule Neoprice.EtsProcess do
  use GenServer

  # Callbacks

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  def create_table(name) do
    GenServer.call(__MODULE__, {:create, name})
  end

  @impl true
  def handle_call({:create, name}, _from, state) do
    unless name in :ets.all() do
      :ets.new(name, [:public, :ordered_set, :named_table, {:read_concurrency, true}])
    end

    {:reply, :ok, state}
  end
end