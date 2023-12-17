defmodule LiveViewStudio.Servers.Server do
  use Ecto.Schema
  import Ecto.Changeset

  schema "servers" do
    field :name, :string
    field :status, :string, default: "down"
    field :deploy_count, :integer, default: 0
    field :size, :float
    field :framework, :string, default: ""
    field :last_commit_message, :string

    timestamps()
  end

  @doc false
  def changeset(server, attrs) do
    server
    |> cast(attrs, [:name, :status, :deploy_count, :size, :framework, :last_commit_message])
    |> validate_required([:name, :status, :deploy_count, :size, :framework])
    |> validate_length(:name, min: 4, max: 64)
    |> validate_length(:status, min: 2, max: 64)
    |> validate_number(:size, greater_than_or_equal_to: 0)
    |> validate_inclusion(:status, ["up", "down"])
  end
end
