# Copyright (C) 2025 Philip Sampaio Silva
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule TableKittyTest do
  use ExUnit.Case
  doctest TableKitty

  describe "build/2" do
    test "returns a printable IO data" do
      assert {:ok, printable} =
               TableKitty.build([%{"a" => "1", "b" => "2"}, %{"a" => "42", "b" => "6"}])

      assert IO.iodata_to_binary(printable) == """
             +----+---+
             | a  | b |
             +====+===+
             | 1  | 2 |
             +----+---+
             | 42 | 6 |
             +----+---+
             """
    end

    test "returns a printable IO data fitting to the header size" do
      assert {:ok, printable} =
               TableKitty.build([%{"aaaa" => "1", "bb" => "2"}, %{"aaaa" => "42", "bb" => "6"}])

      assert IO.iodata_to_binary(printable) == """
             +------+----+
             | aaaa | bb |
             +======+====+
             | 1    | 2  |
             +------+----+
             | 42   | 6  |
             +------+----+
             """
    end

    test "returns a printable IO data with multiline cells" do
      assert {:ok, printable} =
               TableKitty.build([
                 %{"a" => "Elixir is\nawesome", "b" => 42},
                 %{"a" => "Phoenix is great", "b" => 54}
               ])

      assert IO.iodata_to_binary(printable) == """
             +------------------+----+
             | a                | b  |
             +==================+====+
             | Elixir is        | 42 |
             | awesome          |    |
             +------------------+----+
             | Phoenix is great | 54 |
             +------------------+----+
             """
    end

    test "returns a printable IO data with multiline header" do
      assert {:ok, printable} =
               TableKitty.build([
                 %{"this is\na long title" => "Elixir is\nawesome", "b" => 42},
                 %{"this is\na long title" => "Phoenix is great", "b" => 54}
               ])

      assert IO.iodata_to_binary(printable) == """
             +----+------------------+
             | b  | this is          |
             |    | a long title     |
             +====+==================+
             | 42 | Elixir is        |
             |    | awesome          |
             +----+------------------+
             | 54 | Phoenix is great |
             +----+------------------+
             """
    end

    test "returns a printable IO data with a header" do
      assert {:ok, printable} =
               TableKitty.build([%{"a" => "1", "b" => "2"}, %{"a" => "42", "b" => "6"}],
                 title: "A nice table"
               )

      assert IO.iodata_to_binary(printable) == """
             +--------------+
             | A nice table |
             +-------+------+
             | a     | b    |
             +=======+======+
             | 1     | 2    |
             +-------+------+
             | 42    | 6    |
             +-------+------+
             """
    end

    test "returns a printable IO data with a header shorter than columns" do
      assert {:ok, printable} =
               TableKitty.build([%{"a" => "1", "b" => "2"}, %{"a" => "42", "b" => "6"}],
                 title: "tb"
               )

      assert IO.iodata_to_binary(printable) == """
             +--------+
             | tb     |
             +----+---+
             | a  | b |
             +====+===+
             | 1  | 2 |
             +----+---+
             | 42 | 6 |
             +----+---+
             """
    end

    test "returns a printable IO data with headers aligned to the right" do
      assert {:ok, printable} =
               TableKitty.build(
                 [
                   [name: "Mary Jane", born_in: "Manhattan, NY - USA"],
                   [name: "Peter Park", born_in: "Manhattan, NY - USA"]
                 ],
                 align_headers: :right
               )

      assert IO.iodata_to_binary(printable) == """
             +------------+---------------------+
             |       name |             born_in |
             +============+=====================+
             | Mary Jane  | Manhattan, NY - USA |
             +------------+---------------------+
             | Peter Park | Manhattan, NY - USA |
             +------------+---------------------+
             """
    end

    test "returns a printable IO data with one header aligned to the right" do
      assert {:ok, printable} =
               TableKitty.build(
                 [
                   [name: "Mary Jane", born_in: "Manhattan, NY - USA"],
                   [name: "Peter Park", born_in: "Manhattan, NY - USA"]
                 ],
                 align_headers: %{born_in: :right}
               )

      assert IO.iodata_to_binary(printable) == """
             +------------+---------------------+
             | name       |             born_in |
             +============+=====================+
             | Mary Jane  | Manhattan, NY - USA |
             +------------+---------------------+
             | Peter Park | Manhattan, NY - USA |
             +------------+---------------------+
             """
    end

    test "returns a printable IO data with headers aligned to the center" do
      assert {:ok, printable} =
               TableKitty.build(
                 [
                   [name: "Mary Jane", born_in: "Manhattan, NY - USA"],
                   [name: "Peter Park", born_in: "Manhattan, NY - USA"]
                 ],
                 align_headers: :center
               )

      assert IO.iodata_to_binary(printable) == """
             +------------+---------------------+
             |    name    |       born_in       |
             +============+=====================+
             | Mary Jane  | Manhattan, NY - USA |
             +------------+---------------------+
             | Peter Park | Manhattan, NY - USA |
             +------------+---------------------+
             """
    end

    test "returns a printable IO with table title aligned to the right" do
      assert {:ok, printable} =
               TableKitty.build(
                 [
                   [name: "Mary Jane", born_in: "Manhattan, NY - USA", birth_date: "1991-01-28"],
                   [name: "Peter Park", born_in: "Manhattan, NY - USA", birth_date: "1992-12-20"]
                 ],
                 title: "People from the Spiderman world",
                 align_title: :right
               )

      assert IO.iodata_to_binary(printable) == """
             +-----------------------------------------------+
             |               People from the Spiderman world |
             +------------+---------------------+------------+
             | name       | born_in             | birth_date |
             +============+=====================+============+
             | Mary Jane  | Manhattan, NY - USA | 1991-01-28 |
             +------------+---------------------+------------+
             | Peter Park | Manhattan, NY - USA | 1992-12-20 |
             +------------+---------------------+------------+
             """
    end

    test "returns a printable IO with table title aligned to the center" do
      assert {:ok, printable} =
               TableKitty.build(
                 [
                   [name: "Mary Jane", born_in: "Manhattan, NY - USA", birth_date: "1991-01-28"],
                   [name: "Peter Park", born_in: "Manhattan, NY - USA", birth_date: "1992-12-20"]
                 ],
                 title: "People from the Spiderman world",
                 align_title: :center
               )

      assert IO.iodata_to_binary(printable) == """
             +-----------------------------------------------+
             |        People from the Spiderman world        |
             +------------+---------------------+------------+
             | name       | born_in             | birth_date |
             +============+=====================+============+
             | Mary Jane  | Manhattan, NY - USA | 1991-01-28 |
             +------------+---------------------+------------+
             | Peter Park | Manhattan, NY - USA | 1992-12-20 |
             +------------+---------------------+------------+
             """
    end

    test "returns a printable IO with table content aligned to the right" do
      assert {:ok, printable} =
               TableKitty.build(
                 %{
                   "a big column name" => ["Ana", "Bob", "John"],
                   "another big column" => [3.53, 4.20, 11.5]
                 },
                 align_content: :right
               )

      assert IO.iodata_to_binary(printable) == """
             +-------------------+--------------------+
             | a big column name | another big column |
             +===================+====================+
             |               Ana |               3.53 |
             +-------------------+--------------------+
             |               Bob |                4.2 |
             +-------------------+--------------------+
             |              John |               11.5 |
             +-------------------+--------------------+
             """
    end

    test "returns a printable IO with one column content aligned to the right" do
      assert {:ok, printable} =
               TableKitty.build(
                 %{
                   "a big column name" => ["Ana", "Bob", "John"],
                   "another big column" => [3.53, 4.20, 11.5]
                 },
                 align_content: %{"another big column" => :right}
               )

      assert IO.iodata_to_binary(printable) == """
             +-------------------+--------------------+
             | a big column name | another big column |
             +===================+====================+
             | Ana               |               3.53 |
             +-------------------+--------------------+
             | Bob               |                4.2 |
             +-------------------+--------------------+
             | John              |               11.5 |
             +-------------------+--------------------+
             """
    end

    test "returns a printable IO with one column content aligned to the center" do
      assert {:ok, printable} =
               TableKitty.build(
                 %{
                   "a big column name" => ["Ana", "Bob", "John"],
                   "another big column" => [3.53, 4.20, 11.5]
                 },
                 align_content: %{"a big column name" => :center}
               )

      assert IO.iodata_to_binary(printable) == """
             +-------------------+--------------------+
             | a big column name | another big column |
             +===================+====================+
             |        Ana        | 3.53               |
             +-------------------+--------------------+
             |        Bob        | 4.2                |
             +-------------------+--------------------+
             |       John        | 11.5               |
             +-------------------+--------------------+
             """
    end

    test "returns a printable IO with custom names for the headers" do
      assert {:ok, printable} =
               TableKitty.build(
                 %{
                   "a big column name" => ["Ana", "Bob", "John"],
                   "another big column" => [3.53, 4.20, 11.5]
                 },
                 headers: %{"a big column name" => "name"}
               )

      assert IO.iodata_to_binary(printable) == """
             +------+--------------------+
             | name | another big column |
             +======+====================+
             | Ana  | 3.53               |
             +------+--------------------+
             | Bob  | 4.2                |
             +------+--------------------+
             | John | 11.5               |
             +------+--------------------+
             """
    end

    test "returns a printable IO without headers" do
      assert {:ok, printable} =
               TableKitty.build(
                 %{
                   "name" => ["Ana", "Bob", "John"],
                   "rate" => [5.0, 4.35, 4.75]
                 },
                 headers: false
               )

      assert IO.iodata_to_binary(printable) == """
             +------+------+
             | Ana  | 5.0  |
             +------+------+
             | Bob  | 4.35 |
             +------+------+
             | John | 4.75 |
             +------+------+
             """
    end

    test "returns a printable IO with custom headers formatter" do
      assert {:ok, printable} =
               TableKitty.build(
                 %{
                   "name" => ["Ana", "Bob", "John"],
                   "rate" => [5.0, 4.35, 4.75]
                 },
                 formatter: fn %{context: context, value: value}, _opts ->
                   if context == :header and value == "name", do: "NAME", else: to_string(value)
                 end
               )

      assert IO.iodata_to_binary(printable) == """
             +------+------+
             | NAME | rate |
             +======+======+
             | Ana  | 5.0  |
             +------+------+
             | Bob  | 4.35 |
             +------+------+
             | John | 4.75 |
             +------+------+
             """
    end

    test "returns a printable IO with custom value formatter" do
      formatter = fn
        %{context: :row, column: col, value: value}, _opts when col == "rate" ->
          "$" <> to_string(value)

        context, _opts ->
          Map.fetch!(context, :value)
      end

      assert {:ok, printable} =
               TableKitty.build(
                 %{
                   "name" => ["Ana", "Bob", "John"],
                   "rate" => [5.0, 4.35, 4.75]
                 },
                 formatter: formatter
               )

      assert IO.iodata_to_binary(printable) == """
             +------+-------+
             | name | rate  |
             +======+=======+
             | Ana  | $5.0  |
             +------+-------+
             | Bob  | $4.35 |
             +------+-------+
             | John | $4.75 |
             +------+-------+
             """
    end

    @tag skip: "The output is different from SO to SO."
    test "returns a printable IO with custom value styler" do
      styler = fn
        %{context: :row, column: col, value: val}, _opts when col == "rate" and val == "5.0" ->
          IO.ANSI.format([:blue_background, val])

        context, _opts ->
          Map.fetch!(context, :value)
      end

      assert {:ok, printable} =
               TableKitty.build(
                 %{
                   "name" => ["Ana", "Bob", "John"],
                   "rate" => [5.0, 4.35, 4.75]
                 },
                 styler: styler
               )

      assert IO.iodata_to_binary(printable) == """
             +------+------+
             | name | rate |
             +======+======+
             | Ana  | \e[44m5.0\e[0m  |
             +------+------+
             | Bob  | 4.35 |
             +------+------+
             | John | 4.75 |
             +------+------+
             """
    end

    test "returns a printable IO without top border" do
      assert {:ok, printable} =
               TableKitty.build(
                 %{
                   "name" => ["Ana", "Bob", "John"],
                   "rate" => [5.0, 4.35, 4.75]
                 },
                 display_top_border: false
               )

      assert IO.iodata_to_binary(printable) == """
             | name | rate |
             +======+======+
             | Ana  | 5.0  |
             +------+------+
             | Bob  | 4.35 |
             +------+------+
             | John | 4.75 |
             +------+------+
             """
    end

    test "returns a printable IO without bottom border" do
      assert {:ok, printable} =
               TableKitty.build(
                 %{
                   "name" => ["Ana", "Bob", "John"],
                   "rate" => [5.0, 4.35, 4.75]
                 },
                 display_bottom_border: false
               )

      assert IO.iodata_to_binary(printable) == """
             +------+------+
             | name | rate |
             +======+======+
             | Ana  | 5.0  |
             +------+------+
             | Bob  | 4.35 |
             +------+------+
             | John | 4.75 |
             """
    end

    test "returns a printable IO without vertical divisors" do
      assert {:ok, printable} =
               TableKitty.build(
                 %{
                   "name" => ["Ana", "Bob", "John"],
                   "rate" => [5.0, 4.35, 4.75]
                 },
                 display_vertical_divisor: false
               )

      assert IO.iodata_to_binary(printable) == """
             +------+------+
             | name | rate |
             +======+======+
             | Ana  | 5.0  |
             | Bob  | 4.35 |
             | John | 4.75 |
             +------+------+
             """
    end

    test "reproduces the Explorer print style" do
      # Using list of pairs to preserve column order.
      data = [
        {"sepal_length", [5.1, 4.9, 4.7, 4.6, 5.0]},
        {"sepal_width", [3.5, 3.0, 3.2, 3.1, 3.6]},
        {"petal_length", [1.4, 1.4, 1.3, 1.5, 1.4]},
        {"petal_width", [0.2, 0.2, 0.2, 0.2, 0.2]},
        {"species", ["Iris-setosa", "Iris-setosa", "Iris-setosa", "Iris-setosa", "Iris-setosa"]}
      ]

      dtypes = %{
        "sepal_length" => "<f64>",
        "sepal_width" => "<f64>",
        "petal_length" => "<f64>",
        "petal_width" => "<f64>",
        "species" => "<string>"
      }

      custom_headers =
        Map.new(dtypes, fn {column, dtype} -> {column, column <> "\n" <> dtype} end)

      assert {:ok, printable} =
               TableKitty.build(data,
                 title: "Explorer DataFrame: [rows: 10, columns: 5]",
                 headers: custom_headers,
                 align_headers: :center,
                 align_title: :center
               )

      # Explorer.Datasets.iris() |> Explorer.DataFrame.print()
      expected = """
      +-----------------------------------------------------------------------+
      |              Explorer DataFrame: [rows: 10, columns: 5]               |
      +--------------+-------------+--------------+-------------+-------------+
      | sepal_length | sepal_width | petal_length | petal_width |   species   |
      |    <f64>     |    <f64>    |    <f64>     |    <f64>    |  <string>   |
      +==============+=============+==============+=============+=============+
      | 5.1          | 3.5         | 1.4          | 0.2         | Iris-setosa |
      +--------------+-------------+--------------+-------------+-------------+
      | 4.9          | 3.0         | 1.4          | 0.2         | Iris-setosa |
      +--------------+-------------+--------------+-------------+-------------+
      | 4.7          | 3.2         | 1.3          | 0.2         | Iris-setosa |
      +--------------+-------------+--------------+-------------+-------------+
      | 4.6          | 3.1         | 1.5          | 0.2         | Iris-setosa |
      +--------------+-------------+--------------+-------------+-------------+
      | 5.0          | 3.6         | 1.4          | 0.2         | Iris-setosa |
      +--------------+-------------+--------------+-------------+-------------+
      """

      assert IO.iodata_to_binary(printable) == expected
    end

    test "returns printable IO data with lists" do
      assert {:ok, printable} =
               TableKitty.build([
                 {"name", ["Ana", "Bob"]},
                 {"list",
                  [
                    [1, 2],
                    [3, 4]
                  ]}
               ])

      assert IO.iodata_to_binary(printable) == """
             +------+------+
             | name | list |
             +======+======+
             | Ana  | [    |
             |      |  1   |
             |      |  2   |
             |      | ]    |
             +------+------+
             | Bob  | [    |
             |      |  3   |
             |      |  4   |
             |      | ]    |
             +------+------+
             """
    end

    test "returns printable IO data with nested lists and nils" do
      assert {:ok, printable} =
               TableKitty.build([
                 {"name", ["Ana", "Bob"]},
                 {"list",
                  [
                    [[1, 2], [3, 4]],
                    [[150, -10, nil], [4, 9]]
                  ]}
               ])

      assert IO.iodata_to_binary(printable) == """
             +------+-------+
             | name | list  |
             +======+=======+
             | Ana  | [     |
             |      |  [    |
             |      |   1   |
             |      |   2   |
             |      |  ]    |
             |      |  [    |
             |      |   3   |
             |      |   4   |
             |      |  ]    |
             |      | ]     |
             +------+-------+
             | Bob  | [     |
             |      |  [    |
             |      |   150 |
             |      |   -10 |
             |      |   nil |
             |      |  ]    |
             |      |  [    |
             |      |   4   |
             |      |   9   |
             |      |  ]    |
             |      | ]     |
             +------+-------+
             """
    end

    test "returns printable IO data with maps" do
      assert {:ok, printable} =
               TableKitty.build([
                 {"name", ["Ana", "Bob"]},
                 {"maps",
                  [
                    %{a: 1, b: 2},
                    %{a: 3, b: 4}
                  ]}
               ])

      assert IO.iodata_to_binary(printable) == """
             +------+-------+
             | name | maps  |
             +======+=======+
             | Ana  | {     |
             |      |  a: 1 |
             |      |  b: 2 |
             |      | }     |
             +------+-------+
             | Bob  | {     |
             |      |  a: 3 |
             |      |  b: 4 |
             |      | }     |
             +------+-------+
             """
    end

    test "returns printable IO data with nested maps" do
      assert {:ok, printable} =
               TableKitty.build([
                 {"name", ["Ana", "Bob"]},
                 {"maps",
                  [
                    %{a: %{d: %{g: 1, z: 4}}, b: 2},
                    %{a: 3, b: %{j: %{k: 7}}}
                  ]}
               ])

      assert IO.iodata_to_binary(printable) == """
             +------+-----------------+
             | name | maps            |
             +======+=================+
             | Ana  | {               |
             |      |  a: {           |
             |      |   d: {          |
             |      |    g: 1         |
             |      |    z: 4         |
             |      |   }             |
             |      |  }              |
             |      |  b: 2           |
             |      | }               |
             +------+-----------------+
             | Bob  | {               |
             |      |  a: 3           |
             |      |  b: {j: {k: 7}} |
             |      | }               |
             +------+-----------------+
             """
    end

    test "returns printable IO data with binaries" do
      assert {:ok, printable} =
               TableKitty.build([
                 {"name", ["Ana", "Bob"]},
                 {"bins",
                  [
                    <<72, 250, 7, 198, 137, 82>>,
                    <<192, 167, 151, 250, 214, 131>>
                  ]}
               ])

      assert IO.iodata_to_binary(printable) == """
             +------+------+
             | name | bins |
             +======+======+
             | Ana  | <<   |
             |      |  72  |
             |      |  250 |
             |      |  7   |
             |      |  198 |
             |      |  137 |
             |      |  82  |
             |      | >>   |
             +------+------+
             | Bob  | <<   |
             |      |  192 |
             |      |  167 |
             |      |  151 |
             |      |  250 |
             |      |  214 |
             |      |  131 |
             |      | >>   |
             +------+------+
             """
    end
  end
end
