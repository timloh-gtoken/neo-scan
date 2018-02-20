defmodule Neoscan.BalanceHistories.History do
  @moduledoc """
  Represent a History of a transaction in Database.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Neoscan.BalanceHistories.History

  @derive {Poison.Encoder, except: [:__meta__, :__struct__]}
  schema "histories" do
    field(:address_hash, :string)
    field(:txid, :string)
    field(:balance, :map)
    field(:block_height, :integer)
    field(:time, :integer)

    belongs_to(:address, Neoscan.Addresses.Address)
    timestamps()
  end

  @doc false
  def changeset(%History{} = history, address, attrs) do
    new_attrs =
      Map.merge(attrs, %{
        :address_id => address.id,
        :address_hash => address.address
      })

    history
    |> cast(new_attrs, [:address_hash, :balance, :txid, :block_height, :address_id, :time])
    |> assoc_constraint(:address, required: true)
    |> validate_required([:address_hash, :txid, :block_height, :address_id, :time])
  end
end
