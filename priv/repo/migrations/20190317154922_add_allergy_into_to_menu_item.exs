defmodule PlateSlate.Repo.Migrations.AddAllergyIntoToMenuItem do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add(:allergy_info, :map)
    end
  end
end
