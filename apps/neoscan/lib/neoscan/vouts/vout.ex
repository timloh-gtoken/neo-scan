defmodule Neoscan.Vouts.Vout do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Neoscan.Vouts.Vout
  alias Neoscan.ChainAssets

  @derive {Poison.Encoder, except: [:__meta__, :__struct__]}
  schema "vouts" do
    field(:asset, :string)
    field(:address_hash, :string)
    field(:n, :integer)
    field(:value, :float)
    field(:txid, :string)
    field(:time, :integer)

    field(:start_height, :integer)
    field(:end_height, :integer)
    field(:claimed, :boolean)

    # colum for composed query indexing
    field(:query, :string)

    belongs_to(:transaction, Neoscan.Transactions.Transaction)
    belongs_to(:address, Neoscan.Addresses.Address)
    timestamps()
  end

  @doc false
  def changeset(
        %{
          :id => transaction_id,
          :txid => txid,
          :time => time,
          :block_height => height
        },
        %{
          "address" => {address, _attrs},
          "value" => value,
          "n" => n,
          "asset" => asset
        } = attrs \\ %{}
      ) do
    {new_value, _} = Float.parse(value)

    verified_asset = ChainAssets.verify_asset(String.slice(to_string(asset), -64..-1), time)

    new_attrs =
      attrs
      |> Map.merge(%{
        "start_height" => height,
        "claimed" => false,
        "time" => time,
        "asset" => verified_asset,
        "address_id" => address.id,
        "transaction_id" => transaction_id,
        "address_hash" => address.address,
        "txid" => txid,
        "value" => new_value,
        "query" => "#{txid}#{n}"
      })
      |> Map.delete("address")

    %Vout{}
    |> cast(new_attrs, [
      :asset,
      :address_hash,
      :n,
      :value,
      :address_id,
      :transaction_id,
      :txid,
      :query,
      :time,
      :start_height,
      :end_height,
      :claimed
    ])
    |> assoc_constraint(:transaction, required: true)
    |> assoc_constraint(:address, required: true)
    |> validate_required([
      :asset,
      :address_hash,
      :n,
      :value,
      :txid,
      :query,
      :time,
      :start_height
    ])
  end

  def update_changeset(vout, %{:end_height => _endheight} = attrs) do
    vout
    |> cast(attrs, [:end_height])
  end

  def update_changeset(vout, %{:claimed => _claimed} = attrs) do
    vout
    |> cast(attrs, [:claimed])
  end
end
