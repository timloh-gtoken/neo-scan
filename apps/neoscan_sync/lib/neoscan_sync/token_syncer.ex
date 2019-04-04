defmodule NeoscanSync.TokenSyncer do
  alias Neoscan.Repo
  alias Neoscan.Asset

  use GenServer

  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    {:ok, %{contracts: []}}
  end

  @impl true
  def handle_cast({:contract, index, contract}, %{contracts: contracts} = state) do
    state =
      if contract in contracts do
        state
      else
        get_token(index, contract)
        %{state | contracts: [contract | contracts]}
      end

    {:noreply, state}
  end

  def retrieve_contract(index, contract) do
    GenServer.cast(__MODULE__, {:contract, index, contract})
  end

  def get_token(index, contract) do
    try do
      {:ok, token} =
        NeoscanNode.get_nep5_token_from_contract(index, Base.encode16(contract, case: :lower))

      Repo.insert(convert_token_to_asset(contract, token), on_conflict: :nothing)
    catch
      error, reason ->
        Logger.error("error while getting token block #{inspect({contract, error, reason})}")
        get_token(index, contract)
    end
  end

  def convert_token_to_asset(contract, token) do
    %Asset{
      admin: <<0>>,
      amount: 0.0,
      name: %{"en" => token.name},
      symbol: token.symbol,
      owner: <<0>>,
      precision: token.decimals,
      type: "NEP5",
      issued: 0.0,
      block_time: DateTime.utc_now(),
      contract: <<0>>,
      transaction_hash: contract,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end
end
