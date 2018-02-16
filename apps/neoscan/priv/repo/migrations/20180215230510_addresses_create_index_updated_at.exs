defmodule Neoscan.Repo.Migrations.AddressesCreateIndexUpdatedAt do
  use Ecto.Migration

  def change do
    create(index(:addresses, ["updated_at DESC NULLS LAST"]))
  end
end
