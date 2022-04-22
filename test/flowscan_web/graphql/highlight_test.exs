defmodule FlowscanWeb.Graphql.HighlightTest do
  @moduledoc false
  use FlowscanWeb.ConnCase
  import Flowscan.AbsintheHelpers

  setup [:setup_factories]

  @highlight_feed_query """
  query highlighs {
    highlights {
      id
      date
      refId
      type
      ticker
      title
      subtitle
      info
      sentiment
      isPlus
      indicators
    }
  }
  """

  @recent_highlights_query """
  query recentHighlighs {
    recentHighlights {
      id
      refId
      type
      ticker
      title
      subtitle
      info
      sentiment
      isPlus
      indicators
    }
  }
  """

  @highlight_category_query """
  query highlightCategories {
    highlightCategories {
      id
      title
      description
      highlights {
        id
        refId
        type
        ticker
        title
        subtitle
        info
        sentiment
        isPlus
      }
    }
  }
  """

  @featured_highlights_query """
  query featuredHighlights {
    featuredHighlights {
      id
      refId
      type
      ticker
      title
      subtitle
      info
      sentiment
      isPlus
    }
  }
  """

  test "retrieve categories sorted by weight and latest highlights for each category", %{
    conn: conn,
    free_user: free_user
  } do
    cat_one = insert(:highlight_category)
    cat_two = insert(:highlight_category, weight: 20)
    cat_three = insert(:highlight_category, weight: 10)
    insert_list(11, :highlight, category: cat_one)
    insert_list(2, :highlight, category: cat_two, is_featured: true)
    insert(:highlight, category: cat_two, is_published: false)
    highlight = insert(:highlight, category: cat_three)

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@highlight_category_query))

    data = json_response(res, 200)["data"]["highlightCategories"]
    assert length(data) == 3

    cat_data = data |> Enum.at(0)
    assert cat_data["id"] == cat_two.id
    assert cat_data["title"] == cat_two.title
    assert cat_data["description"] == cat_two.description
    assert length(cat_data["highlights"]) == 2

    cat_data = data |> Enum.at(1)
    assert cat_data["id"] == cat_three.id
    assert length(cat_data["highlights"]) == 1
    highlight_data = hd(cat_data["highlights"])
    assert highlight_data["id"] == highlight.id
    assert highlight_data["refId"] == highlight.ref_id
    assert highlight_data["type"] == Atom.to_string(highlight.type)
    assert highlight_data["ticker"] == highlight.ticker
    assert highlight_data["title"] == highlight.title
    assert highlight_data["subtitle"] == highlight.subtitle
    assert highlight_data["info"] == highlight.info
    assert highlight_data["sentiment"] == Atom.to_string(highlight.sentiment)
    assert highlight_data["isPlus"] == highlight.is_plus

    cat_data = data |> Enum.at(2)
    assert cat_data["id"] == cat_one.id
    assert length(cat_data["highlights"]) == 10
  end

  test "unauthenticated user can't access highlight categories", %{
    conn: conn
  } do
    res =
      conn
      |> graphql(query(@highlight_category_query))

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "NOT_AUTHENTICATED"
  end

  test "retrieve featured highlights", %{conn: conn, free_user: free_user} do
    insert_list(2, :highlight)
    insert_list(2, :highlight, is_featured: true)

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@featured_highlights_query))

    data = json_response(res, 200)["data"]["featuredHighlights"]
    assert length(data) == 2
  end

  test "unauthenticated user can't access featured highlights", %{
    conn: conn
  } do
    res =
      conn
      |> graphql(query(@featured_highlights_query))

    response = json_response(res, 200)
    assert hd(response["errors"])["message"] == "NOT_AUTHENTICATED"
  end

  test "highlight feed returns highlights for past 10 days", %{conn: conn, free_user: free_user} do
    most_recent = insert(:highlight, inserted_at: Timex.now())
    _second_most_recent = insert(:highlight, inserted_at: Timex.now() |> Timex.shift(days: -1))
    third_most_recent = insert(:highlight, inserted_at: Timex.now() |> Timex.shift(days: -2))
    insert(:highlight, inserted_at: Timex.now() |> Timex.shift(days: -8))
    insert(:highlight, inserted_at: Timex.now() |> Timex.shift(days: -10))
    insert(:highlight, inserted_at: Timex.now() |> Timex.shift(days: -11))

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@highlight_feed_query))

    data = json_response(res, 200)["data"]["highlights"]
    assert length(data) == 5
    assert hd(data)["id"] == most_recent.id
    assert Enum.at(data, 2)["id"] == third_most_recent.id
  end

  test "recent highlights query returns 10 most recent highlight entries", %{
    conn: conn,
    free_user: free_user
  } do
    most_recent = insert(:highlight, inserted_at: Timex.now())
    _second_most_recent = insert(:highlight, inserted_at: Timex.now() |> Timex.shift(days: -1))
    third_most_recent = insert(:highlight, inserted_at: Timex.now() |> Timex.shift(days: -2))
    insert_list(8, :highlight, inserted_at: Timex.now() |> Timex.shift(days: -8))

    res =
      conn
      |> authenticate_conn(free_user)
      |> graphql(query(@recent_highlights_query))

    data = json_response(res, 200)["data"]["recentHighlights"]
    assert length(data) == 10
    assert hd(data)["id"] == most_recent.id
    assert Enum.at(data, 2)["id"] == third_most_recent.id
  end

  defp setup_factories(_) do
    %{
      free_user: insert(:user, is_plus: false)
    }
  end

  # This should be moved out to helpers
  defp graphql(conn, query) do
    conn |> post("/graphql", query)
  end
end
