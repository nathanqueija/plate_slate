# ---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
# ---
defmodule PlateSlateWeb.Schema.Query.MenuItemsTest do
  use PlateSlateWeb.ConnCase, async: true

  alias PlateSlate.{Repo, Menu}

  import Ecto.Query

  setup do
    PlateSlate.Seeds.run()

    category_id =
      from(t in Menu.Category, where: t.name == "Sandwiches")
      |> Repo.one!()
      |> Map.fetch!(:id)
      |> to_string

    {:ok, category_id: category_id}
  end

  @query """
  {
    menuItems(filter: {}) {
      name
    }
  }
  """

  @query_with_params """
  query MenuItems($filter: MenuItemFilter!){
    menuItems(filter: $filter) {
      name,
      addedOn
    }
  }
  """

  @query_with_params2 """
  query{
    menuItems(filter: {
      name: "eub"
    }) {
      name
    }
  }
  """

  @query_with_vars """
  query MenuItems($order: SortOrder!, $filter: MenuItemFilter!){
    menuItems(order: $order, filter: $filter){
      name
    }
  }

  """

  @query_invalid """
  {
    menuItems(filter: {name: 123}) {
      name
    }
  }
  """

  @query_filter """
  query MenuItems($filter: MenuItemFilter!){
    menuItems(filter: $filter) {
      name
    }
  }
  """

  @query_search """
  query Search($term: String!){
    search(matching: $term){
      ... on MenuItem{name}
      ... on Category {name}
      __typename
    }
  }
  """

  @query_search_interface """
  query Search($term: String!){
    search(matching: $term){
     name
      __typename
    }
  }
  """

  @mutation """
  mutation($menuItem: MenuItemInput!){
    createMenuItem(input: $menuItem){
      name
      description
      price
    }
  }
  """

  test "menuItems field returns menu items" do
    conn = build_conn()
    conn = get(conn, "/api", query: @query)

    assert json_response(conn, 200) == %{
             "data" => %{
               "menuItems" => [
                 %{"name" => "Bánh mì"},
                 %{"name" => "Chocolate Milkshake"},
                 %{"name" => "Croque Monsieur"},
                 %{"name" => "French Fries"},
                 %{"name" => "Lemonade"},
                 %{"name" => "Masala Chai"},
                 %{"name" => "Muffuletta"},
                 %{"name" => "Papadum"},
                 %{"name" => "Pasta Salad"},
                 %{"name" => "Reuben"},
                 %{"name" => "Soft Drink"},
                 %{"name" => "Vada Pav"},
                 %{"name" => "Vanilla Milkshake"},
                 %{"name" => "Water"}
               ]
             }
           }
  end

  test "menuItems field returns menu items filtered by name" do
    response = get(build_conn(), "/api", query: @query_with_params2)

    assert json_response(response, 200) == %{
             "data" => %{
               "menuItems" => [
                 %{"name" => "Reuben"}
               ]
             }
           }
  end

  test "menuItems field returns error when submitting invalid parameters" do
    response = get(build_conn(), "/api", query: @query_invalid)

    assert %{
             "errors" => [
               %{"message" => message}
             ]
           } = json_response(response, 200)

    assert message ==
             "Argument \"filter\" has invalid value {name: 123}.\nIn field \"name\": Expected type \"String\", found 123."
  end

  test "menuItems field returns items when providing variable" do
    variables = %{
      filter: %{
        "name" => "eub"
      }
    }

    response = get(build_conn(), "/api", query: @query_with_params, variables: variables)

    assert json_response(response, 200) == %{
             "data" => %{
               "menuItems" => [
                 %{"name" => "Reuben", "addedOn" => "2019-03-16"}
               ]
             }
           }
  end

  test "menuItems fields returns items ascending using literals" do
    variables = %{"order" => "DESC", "filter" => %{}}
    response = get(build_conn(), "/api", query: @query_with_vars, variables: variables)

    assert %{
             "data" => %{"menuItems" => [%{"name" => "Water"} | _]}
           } = json_response(response, 200)
  end

  test "menuItems field returns menuItems filtering with a literal" do
    variables = %{
      filter: %{
        "tag" => "Vegetarian",
        "category" => "Sandwiches"
      }
    }

    response = get(build_conn(), "/api", query: @query_filter, variables: variables)

    assert %{
             "data" => %{
               "menuItems" => [
                 %{"name" => "Vada Pav"}
               ]
             }
           } == json_response(response, 200)
  end

  test "menuItems filtered by a custom scalar" do
    variables = %{
      filter: %{
        "addedBefore" => "2017-01-20"
      }
    }

    side = PlateSlate.Repo.get_by!(PlateSlate.Menu.Category, name: "Sides")

    %PlateSlate.Menu.Item{
      name: "Garlic Fries",
      added_on: ~D[2017-01-01],
      price: 2.50,
      category: side
    }
    |> PlateSlate.Repo.insert!()

    response = get(build_conn(), "/api", query: @query_with_params, variables: variables)

    assert %{
             "data" => %{
               "menuItems" => [
                 %{
                   "name" => "Garlic Fries",
                   "addedOn" => "2017-01-01"
                 }
               ]
             }
           } == json_response(response, 200)
  end

  test "search returns a list of menu items and categories" do
    variables = %{term: "e"}
    response = get(build_conn(), "/api", query: @query_search_interface, variables: variables)
    assert %{"data" => %{"search" => results}} = json_response(response, 200)
    assert length(results) > 0
    assert Enum.find(results, &(&1["__typename"] == "Category"))
    assert Enum.find(results, &(&1["__typename"] == "MenuItem"))
  end

  test "createMenuItem mutation creates an item", %{category_id: category_id} do
    menu_item = %{
      "name" => "French Dip",
      "description" => "Roast beef, caramelized onions...",
      "price" => "5.75",
      "categoryId" => category_id
    }

    conn = build_conn()
    conn = post(conn, "/api", query: @mutation, variables: %{"menuItem" => menu_item})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createMenuItem" => %{
                 "name" => menu_item["name"],
                 "description" => menu_item["description"],
                 "price" => menu_item["price"]
               }
             }
           }
  end
end
