defmodule FlowscanWeb.Schema.HighlightCategoryTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  alias Flowscan.Highlight

  object :highlight_category do
    field :id, :integer
    field :title, :string
    field :description, :string

    field :highlights, list_of(:highlight) do
      resolve(fn highlight_category, _, _ ->
        {:ok, Highlight.recent(highlight_category.id, highlight_category.slug)}
      end)
    end
  end
end
