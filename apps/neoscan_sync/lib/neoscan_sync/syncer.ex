defmodule NeoscanSync.Syncer do
  alias Neoscan.Block
  alias Neoscan.Transaction
  alias Neoscan.Vout
  alias Neoscan.Vin
  alias Neoscan.Claim
  alias Neoscan.Repo
  alias Neoscan.BlockGasGeneration
  alias Neoscan.Transfer
  alias Neoscan.Asset

  alias Ecto.ConstraintError

  require Logger

  @parallelism 16

  def convert_claim(claim_raw, block_raw) do
    %Claim{
      vout_n: claim_raw.vout_n,
      vout_transaction_hash: claim_raw.vout_transaction_hash,
      block_time: block_raw.time
    }
  end

  def convert_vin(vin_raw, block_raw) do
    %Vin{
      vout_n: vin_raw.vout_n,
      vout_transaction_hash: vin_raw.vout_transaction_hash,
      block_time: block_raw.time
    }
  end

  def convert_asset(nil, _), do: nil

  def convert_asset(asset_raw, block_raw) do
    %Asset{
      admin: asset_raw.admin,
      amount: asset_raw.amount,
      name: asset_raw.name,
      owner: asset_raw.owner,
      precision: asset_raw.precision,
      type: to_string(asset_raw.type),
      issued: asset_raw.available,
      block_time: block_raw.time,
      contract: <<0>>
    }
  end

  def convert_transfer(transfer_raw, block_raw) do
    %Transfer{
      address_from: transfer_raw.addr_from,
      address_to: transfer_raw.addr_to,
      amount: transfer_raw.amount * 1.0,
      contract: transfer_raw.contract,
      block_index: block_raw.index,
      block_time: block_raw.time
    }
  end

  def convert_vout(vout_raw, block_raw) do
    %Vout{
      n: vout_raw.n,
      address_hash: vout_raw.address,
      value: vout_raw.value,
      asset: vout_raw.asset,
      block_time: block_raw.time
    }
  end

  def convert_transaction(transaction_raw, block_raw) do
    %Transaction{
      hash: transaction_raw.hash,
      block_index: block_raw.index,
      block_time: block_raw.time,
      attributes: transaction_raw.attributes,
      net_fee: transaction_raw.net_fee,
      sys_fee: transaction_raw.sys_fee,
      nonce: transaction_raw.nonce,
      scripts: transaction_raw.scripts,
      size: transaction_raw.size,
      type: to_string(transaction_raw.type),
      version: transaction_raw.version,
      vouts: Enum.map(transaction_raw.vouts, &convert_vout(&1, block_raw)),
      vins: Enum.map(transaction_raw.vins, &convert_vin(&1, block_raw)),
      claims: Enum.map(transaction_raw.claims, &convert_claim(&1, block_raw)),
      transfers: Enum.map(transaction_raw.transfers, &convert_transfer(&1, block_raw)),
      asset: convert_asset(transaction_raw.asset, block_raw)
    }
  end

  def convert_block(block_raw) do
    %Block{
      hash: block_raw.hash,
      index: block_raw.index,
      merkle_root: block_raw.merkle_root,
      previous_block_hash: block_raw.previous_block_hash,
      next_block_hash: block_raw.next_block_hash,
      next_consensus: block_raw.next_consensus,
      nonce: block_raw.nonce,
      script: block_raw.script,
      size: block_raw.size,
      time: block_raw.time,
      version: block_raw.version,
      transactions: Enum.map(block_raw.tx, &convert_transaction(&1, block_raw)),
      total_sys_fee: Enum.sum(Enum.map(block_raw.tx, & &1.sys_fee)),
      total_net_fee: Enum.sum(Enum.map(block_raw.tx, & &1.net_fee)),
      gas_generated: BlockGasGeneration.get_amount_generate_in_block(block_raw.index),
      tx_count: Enum.count(block_raw.tx)
    }
  end

  def download_block(index) do
    try do
      block_raw = NeoscanNode.get_block_with_transfers(index)
      ^index = block_raw.index
      convert_block(block_raw)
    catch
      error ->
        Logger.error("error while downloading block #{inspect({index, error})}")
        download_block(index)

      error, reason ->
        Logger.error("error while downloading block #{inspect({index, error, reason})}")
        download_block(index)
    end
  end

  def insert_block(block) do
    try do
      Repo.transaction(fn -> Repo.insert!(block) end)
    catch
      error ->
        Logger.error("error while loading block #{inspect({block.index, error})}")
        insert_block(block)

      :error, %ConstraintError{constraint: "blocks_pkey"} ->
        Logger.error("block already #{block.index} in the database")

      error, reason ->
        Logger.error("error while loading block #{inspect({block.index, error, reason})}")
        insert_block(block)
    end
  end

  def sync_all() do
    concurrency = System.schedulers_online() * @parallelism

    0..2_300_000
    # 0..1_000_000
    |> Task.async_stream(
      fn n ->
        now = Time.utc_now()
        block = download_block(n)
        Logger.warn("download block #{n} #{Time.diff(Time.utc_now(), now, :microseconds)}}")
        block
      end,
      max_concurrency: concurrency,
      timeout: :infinity,
      ordered: false
    )
    |> Task.async_stream(
      fn {:ok, block} ->
        now = Time.utc_now()
        insert_block(block)

        Logger.warn(
          "insert block #{block.index} #{Time.diff(Time.utc_now(), now, :microseconds)}}"
        )
      end,
      max_concurrency: 1,
      timeout: :infinity
    )
    |> Stream.run()
  end
end
