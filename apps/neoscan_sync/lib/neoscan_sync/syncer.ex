defmodule NeoscanSync.Syncer do
  alias Ecto.ConstraintError

  alias NeoscanSync.Converter
  alias Neoscan.Repo
  alias Neoscan.Blocks
  alias Neoscan.Asset
  use GenServer

  require Logger

  @parallelism 16
  @update_interval 1_000
  @block_chunk_size 5_000

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    missing_block_indexes = Blocks.get_missing_block_indexes()
    Logger.warn("found #{Enum.count(missing_block_indexes)} missing blocks")
    Process.send_after(self(), :sync, 0)
    {:ok, missing_block_indexes}
  end

  defp get_available_block_index_range do
    max_index_in_db = Blocks.get_max_index() + 1
    max_index_available = NeoscanNode.get_last_block_index()

    if max_index_in_db > max_index_available do
      []
    else
      Enum.to_list(max_index_in_db..max_index_available)
    end
  end

  @impl true
  def handle_info(:sync, missing_block_indexes) do
    Process.send_after(self(), :sync, @update_interval)
    available_block_index_range = get_available_block_index_range()
    indexes = missing_block_indexes ++ Enum.take(available_block_index_range, @block_chunk_size)
    sync_indexes(indexes)
    {:noreply, []}
  end

  def download_block(index) do
    try do
      block_raw = NeoscanNode.get_block_with_transfers(index)
      ^index = block_raw.index
      Converter.convert_block(block_raw)
    catch
      error ->
        Logger.error("error while downloading block #{inspect({index, error})}")
        download_block(index)

      error, reason ->
        Logger.error("error while downloading block #{inspect({index, error, reason})}")
        download_block(index)
    end
  end

  def explode_block(block) do
    map = %{
      block: %{block | transactions: []},
      transactions: [],
      vouts: [],
      vins: [],
      claims: [],
      transfers: [],
      assets: []
    }

    Enum.reduce(block.transactions, map, fn transaction, acc ->
      %{
        acc
        | transactions: [
            Map.drop(transaction, [:vouts, :vins, :claims, :transfers, :asset]) | acc.transactions
          ],
          vouts: transaction.vouts ++ acc.vouts,
          vins: transaction.vins ++ acc.vins,
          claims: transaction.claims ++ acc.claims,
          transfers: transaction.transfers ++ acc.transfers,
          assets: if(is_nil(transaction.asset), do: [], else: [transaction.asset]) ++ acc.assets
      }
    end)
  end

  defp insert_all(schema, data) do
    data
    |> Enum.chunk_every(1_000)
    |> Enum.map(&Repo.insert_all(schema, &1, timeout: :infinity))
  end

  defp prepare_vout(vout) do
    "#{bytea(vout.transaction_hash)}\t#{vout.n}\t#{bytea(vout.address_hash)}\t#{
      bytea(vout.asset_hash)
    }\t#{vout.value}\t'#{vout.block_time}'\t#{vout.start_block_index}\t'#{vout.inserted_at}'\t'#{
      vout.updated_at
    }'\n"
  end

  defp prepare_vin(vin) do
    "#{bytea(vin.transaction_hash)}\t#{bytea(vin.vout_transaction_hash)}\t#{vin.vout_n}\t#{
      vin.block_index
    }\t'#{vin.block_time}'\t'#{vin.inserted_at}'\t'#{vin.updated_at}'\n"
  end

  defp prepare_transaction(transaction) do
    transaction = %{
      transaction
      | nonce: if(is_nil(transaction.nonce), do: 0, else: transaction.nonce)
    }

    "#{bytea(transaction.hash)}\t#{bytea(transaction.block_hash)}\t#{transaction.block_index}\t'#{
      transaction.block_time
    }'\t#{array_json(transaction.attributes)}\t#{transaction.net_fee}\t#{transaction.sys_fee}\t#{
      transaction.nonce
    }\t#{array_json(transaction.scripts)}\t#{transaction.size}\t#{transaction.type}\t#{
      transaction.version
    }\t'#{transaction.inserted_at}'\t'#{transaction.updated_at}'\n"
  end

  defp prepare_claim(claim) do
    "#{bytea(claim.transaction_hash)}\t#{bytea(claim.vout_transaction_hash)}\t#{claim.vout_n}\t'#{
      claim.block_time
    }'\t'#{claim.inserted_at}'\t'#{claim.updated_at}'\n"
  end

  defp prepare_transfer(transfer) do
    "#{bytea(transfer.transaction_hash)}\t#{bytea(transfer.address_from)}\t#{
      bytea(transfer.address_to)
    }\t#{transfer.amount}\t#{bytea(transfer.contract)}\t#{transfer.block_index}\t'#{
      transfer.block_time
    }'\t'#{transfer.inserted_at}'\t'#{transfer.updated_at}'\n"
  end

  defp bytea(binary) do
    "\\\\x#{Base.encode16(binary)}"
  end

  defp array_json(array) do
    "{#{
      Enum.join(
        Enum.map(array, &"\"#{String.replace(Poison.encode!(&1), "\"", "\\\\\\\"")}\""),
        ","
      )
    }}"
  end

  def insert_block(block) do
    exploded_block = explode_block(block)

    transaction_stream =
      Ecto.Adapters.SQL.stream(
        Repo,
        "COPY transactions(hash, block_hash, block_index, block_time, attributes, net_fee, sys_fee, nonce, scripts, size, type, version, inserted_at, updated_at) FROM STDIN"
      )

    prepared_transactions = Enum.map(exploded_block.transactions, &prepare_transaction/1)

    vout_stream =
      Ecto.Adapters.SQL.stream(
        Repo,
        "COPY vouts(transaction_hash, n, address_hash, asset_hash, value, block_time, start_block_index, inserted_at, updated_at) FROM STDIN"
      )

    prepared_vouts = Enum.map(exploded_block.vouts, &prepare_vout/1)

    vin_stream =
      Ecto.Adapters.SQL.stream(
        Repo,
        "COPY vins(transaction_hash, vout_transaction_hash, vout_n, block_index, block_time, inserted_at, updated_at) FROM STDIN"
      )

    prepared_vins = Enum.map(exploded_block.vins, &prepare_vin/1)

    claim_stream =
      Ecto.Adapters.SQL.stream(
        Repo,
        "COPY claims(transaction_hash, vout_transaction_hash, vout_n, block_time, inserted_at, updated_at) FROM STDIN"
      )

    prepared_claims = Enum.map(exploded_block.claims, &prepare_claim/1)

    transfer_stream =
      Ecto.Adapters.SQL.stream(
        Repo,
        "COPY transfers(transaction_hash, address_from, address_to, amount, contract, block_index, block_time, inserted_at, updated_at) FROM STDIN"
      )

    prepared_transfers = Enum.map(exploded_block.transfers, &prepare_transfer/1)

    try do
      Repo.transaction(
        fn ->
          Repo.insert!(exploded_block.block, timeout: :infinity)
          Enum.into(prepared_transactions, transaction_stream)
          Enum.into(prepared_vins, vin_stream)
          Enum.into(prepared_vouts, vout_stream)
          Enum.into(prepared_claims, claim_stream)
          Enum.into(prepared_transfers, transfer_stream)
          insert_all(Asset, exploded_block.assets)
        end,
        timeout: :infinity
      )

      :ok
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

  def sync_indexes(indexes) do
    concurrency = System.schedulers_online() * @parallelism

    indexes
    |> Task.async_stream(
      fn n ->
        now = Time.utc_now()
        block = download_block(n)
        Monitor.incr(:download_blocks_time, Time.diff(Time.utc_now(), now, :microseconds))
        Monitor.incr(:download_blocks_count, 1)
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
        Monitor.incr(:insert_blocks_time, Time.diff(Time.utc_now(), now, :microseconds))
        Monitor.incr(:insert_blocks_count, 1)
      end,
      max_concurrency: 1,
      timeout: :infinity
    )
    |> Stream.run()
  end
end
