defmodule FlowscanWeb.Schema.HighlightTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :highlight do
    field :id, :integer
    field :ref_id, :integer
    field :type, :string
    field :ticker, :string
    field :title, :string
    field :subtitle, :string
    field :info, :string
    field :sentiment, :string
    field :is_plus, :boolean
    field :is_featured, :boolean
    field :indicators, list_of(:string)

    field :date, :date do
      resolve(fn highlight, _, _ ->
        {:ok, highlight.inserted_at |> NaiveDateTime.to_date()}
      end)
    end

    # field :plus_required, :boolean do
    #   resolve(fn highlight, _, %{context: context} ->
    #     {:ok, highlight.is_plus && !context[:current_user].is_plus}
    #   end)
    # end
  end
end
