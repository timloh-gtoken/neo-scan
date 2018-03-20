defmodule Neoscan.BalanceHistories do
  @moduledoc false

  import Ecto.Query, warn: false
  alias Neoscan.Repo
  alias Neoscan.BalanceHistories.History
  alias Neoscan.Transactions
  alias Neoscan.Transactions.Transaction
  alias Neoscan.ChainAssets
  alias Neoscan.Transfers

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking address history changes.

  ## Examples

      iex> change_history(history)
      %Ecto.Changeset{source: %History{}}

  """
  def change_history(%History{} = history, address, attrs) do
    History.changeset(history, address, attrs)
  end

  # add a transaction history into an address
  def add_tx_id(attrs, txid, index, time) do
    new_tx = %{
      :txid => txid,
      :balance => attrs.balance,
      :block_height => index,
      :time => time
    }

    %{attrs | tx_ids: new_tx}
  end

  @doc """
  Count total history points for an address.

  ## Examples

      iex> count_histories_for_Address(address_hash)
      50

  """
  def count_hist_for_address(address_hash) do
    query = from(h in History, where: h.address_hash == ^address_hash)
    Repo.aggregate(query, :count, :id)
  end

  def paginate_history_transactions(address_hash, pag) do
    his_query =
      from(
        h in History,
        where: h.address_hash == ^address_hash,
        order_by: [
          desc: h.id
        ],
        select: %{
          txid: h.txid
        },
        limit: 15
      )

    histories =
      Repo.paginate(his_query, page: pag, page_size: 15)
      |> Enum.map(fn %{:txid => txid} -> txid end)

    transaction_query =
      from(
        e in Transaction,
        order_by: [
          desc: e.id
        ],
        where: e.txid in ^histories,
        select: %{
          :id => e.id,
          :type => e.type,
          :time => e.time,
          :txid => e.txid,
          :block_height => e.block_height,
          :block_hash => e.block_hash,
          :vin => e.vin,
          :claims => e.claims,
          :sys_fee => e.sys_fee,
          :net_fee => e.net_fee,
          :size => e.size,
          :asset => e.asset
        }
      )

    transactions = Repo.all(transaction_query)

    vouts =
      Enum.map(transactions, fn tx -> tx.id end)
      |> Transactions.get_transactions_vouts()

    transfers =
      Enum.map(transactions, fn tx -> tx.txid end)
      |> Transfers.get_transactions_transfers()

    transactions
    |> Enum.map(fn tx ->
      Map.merge(tx,
        %{
          :vouts =>
            Enum.filter(vouts, fn vout ->
              vout.transaction_id == tx.id
            end),
          :transfers =>
            Enum.filter(transfers, fn transfer ->
              transfer.txid == tx.txid
            end)
        })
    end)
  end

  def get_graph_data_for_address(address) do
    query =
      from(
        h in History,
        where: h.address_hash == ^address,
        order_by: [
          desc: h.id
        ],
        limit: 25,
        select: map(h, [:balance])
      )

    Repo.all(query)
    |> check_result
  end

  defp check_result([]) do
    nil
  end

  defp check_result(list) do
    list
    |> Enum.map(fn %{:balance => b} -> filter_balance(b) end)
  end

  defp filter_balance(nil) do
    nil
  end

  defp filter_balance(balance) do
    balance
    |> Map.to_list()
    |> Enum.reduce(%{:time => 0, :assets => []}, fn {asset_hash,
                                                     %{"amount" => amount, "time" => time}},
                                                    %{
                                                      :assets => assets
                                                    } ->
      %{
        :time => time,
        :assets => [
          %{
            ChainAssets.get_asset_name_by_hash(asset_hash) => amount
          }
          | assets
        ]
      }
    end)
  end
end
