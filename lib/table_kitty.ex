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
defmodule TableKitty do
  @moduledoc """
  Documentation for `TableKitty`.
  """

  @doc """
  Print the table if the same is valid.

  To see options go to `build/2`.
  """
  @spec print(Table.Reader.t(), Keyword.t()) :: :ok | {:error, Exception.t()}
  def print(tabular, opts \\ []) do
    with {:ok, printable} <- build(tabular, opts) do
      IO.puts(printable)
    end
  end

  @doc """
  Builds IO data with the generated table.

  This function receives a valid tabular data, like a list
  of maps, or a keyword list with keys as column names and values as
  list of values for each column.

  ## Examples

      iex> {:ok, iodata} = TableKitty.build([a: [1, 2], b: [4, 6]])
      iex> IO.iodata_to_binary(iodata)
      \"\"\"
      +---+---+
      | a | b |
      +===+===+
      | 1 | 4 |
      +---+---+
      | 2 | 6 |
      +---+---+
      \"\"\"

      iex> {:ok, iodata} = TableKitty.build([%{a: 1, b: 4}, %{a: 2, b: 6}])
      iex> IO.iodata_to_binary(iodata)
      \"\"\"
      +---+---+
      | a | b |
      +===+===+
      | 1 | 4 |
      +---+---+
      | 2 | 6 |
      +---+---+
      \"\"\"

  """
  @spec build(Table.Reader.t(), Keyword.t()) :: {:ok, IO.chardata()} | {:error, Exception.t()}
  def build(tabular, opts \\ []) do
    opts =
      Keyword.validate!(opts,
        title: nil,
        headers: %{},
        columns: nil,
        line_separator: "-",
        column_separator: "|",
        outer_border: "|",
        junction: "+",
        header_line_separator: "=",
        padding_left: 1,
        padding_right: 1,
        align_headers: :left,
        align_title: :left,
        align_content: :left,
        display_top_border: true,
        display_bottom_border: true,
        display_vertical_divisor: true,
        # Custom opts are for when user wants to send down special opts for the formatter/styler.
        custom_opts: [],
        formatter: &TableKitty.DefaultFormatter.format/2,
        styler: fn context, _opts -> Map.fetch!(context, :value) end,
        blank_space_char: " "
      )

    case Table.Reader.init(tabular) do
      :none ->
        {:error,
         ArgumentError.exception("expected valid tabular data, but got: #{inspect(tabular)}")}

      {_reader_type, %{columns: []}, _enum} ->
        {:error,
         ArgumentError.exception("expected non-empty tabular data, but got: #{inspect(tabular)}")}

      {reader_type, %{columns: columns}, _enum} = reader ->
        custom_headers = Keyword.fetch!(opts, :headers)
        select_columns = Keyword.fetch!(opts, :columns)

        columns =
          if is_list(select_columns) and not Enum.empty?(select_columns) do
            select_columns
          else
            columns
          end

        with {:ok, normalized_columns} <- normalize_columns(columns, custom_headers, opts) do
          case reader_type do
            :rows ->
              render_by_rows(reader, columns, normalized_columns, opts)

            :columns ->
              render_by_columns(reader, columns, normalized_columns, opts)
          end
        end
    end
  end

  defp normalize_columns(columns, _headers = false, _opts),
    do: {:ok, Enum.map(columns, fn _ -> [{"", 0}] end)}

  # Returns a list of lists with each column row.
  # A row can have multiple lines.
  defp normalize_columns(columns, headers, opts) do
    formatter = Keyword.fetch!(opts, :formatter)

    result =
      Enum.reduce_while(columns, [], fn column, acc ->
        if is_map(headers) and is_map_key(headers, column) do
          custom_header = Map.fetch!(headers, column)

          context = %{
            context: :header,
            value: custom_header,
            column: column,
            meta: [:custom_header]
          }

          formatted = formatter.(context, opts)

          if is_binary(formatted) do
            multiline_and_styled = expand_header_to_multiline(%{context | value: formatted}, opts)
            {:cont, [multiline_and_styled | acc]}
          else
            {:halt,
             {:error,
              ArgumentError.exception(
                "a custom header should be converted into a valid string by the formatter, got: #{inspect(formatted)}"
              )}}
          end
        else
          context = %{context: :header, value: column, column: column, meta: []}
          formatted = formatter.(context, opts)

          if is_binary(formatted) do
            multiline_and_styled = expand_header_to_multiline(%{context | value: formatted}, opts)
            {:cont, [multiline_and_styled | acc]}
          else
            {:halt,
             {:error,
              ArgumentError.exception(
                "a header should be converted into a valid string by the formatter, got: #{inspect(formatted)}"
              )}}
          end
        end
      end)

    with list when is_list(list) <- result do
      {:ok, Enum.reverse(list)}
    end
  end

  defp expand_header_to_multiline(context, opts) do
    styler = Keyword.fetch!(opts, :styler)

    %{
      context: :header,
      value: value
    } = context

    value
    |> String.split("\n")
    |> Enum.with_index(fn sub_str, row_line ->
      len = String.length(sub_str)

      context =
        Map.merge(
          %{context | value: sub_str, meta: [:substring, :column_line]},
          %{column_line: row_line, length: len}
        )

      styled = styler.(context, opts)

      {styled, len}
    end)
  end

  defp render_by_rows(reader, columns, normalized_columns, opts) do
    columns_to_normalized =
      columns
      |> Enum.zip(normalized_columns)
      |> Map.new()

    max_lenghts =
      Map.new(columns_to_normalized, fn {column, normalized} ->
        {_, max_len} = Enum.max_by(normalized, fn {_, length} -> length end)
        {column, max_len}
      end)

    formatter = Keyword.fetch!(opts, :formatter)
    styler = Keyword.fetch!(opts, :styler)

    {normalized, max_column_lengths, _total_rows} =
      reader
      |> Table.to_rows()
      |> Enum.reduce({[], max_lenghts, 0}, fn row, {acc, current_max_acc, row_index} ->
        new_row_with_lenghts =
          Map.new(row, fn {key, value} ->
            context = %{context: :row, value: value, column: key, row_index: row_index, meta: []}
            formatted = formatter.(context, opts)

            row_lines =
              formatted
              |> String.split("\n")
              |> Enum.with_index(fn sub_str, index ->
                len = String.length(sub_str)

                context =
                  Map.merge(
                    %{context | value: sub_str, meta: [:substring, :row_line]},
                    %{row_line: index, before: value, formatted: formatted, length: len}
                  )

                styled = styler.(context, opts)

                {styled, len}
              end)

            {key, row_lines}
          end)

        new_max_sizes =
          Map.new(current_max_acc, fn {key, current_max} ->
            row = Map.fetch!(new_row_with_lenghts, key)

            {_, row_length} = Enum.max_by(row, fn {_, length} -> length end)

            {key, max(current_max, row_length)}
          end)

        {[new_row_with_lenghts | acc], new_max_sizes, row_index + 1}
      end)

    normalized = Enum.reverse(normalized)

    pad_left = Keyword.fetch!(opts, :padding_left)
    pad_right = Keyword.fetch!(opts, :padding_right)
    col_sep = Keyword.fetch!(opts, :column_separator)

    {title_len, max_column_lengths} =
      if is_binary(opts[:title]) do
        title_len = String.length(opts[:title])
        column_lengths = Map.values(max_column_lengths) |> Enum.sum()

        structure_spaces =
          (pad_left + pad_right + String.length(to_string(col_sep))) * (length(columns) - 1)

        column_lengths = column_lengths + structure_spaces

        if title_len > column_lengths do
          diff = title_len - column_lengths
          cols = length(columns)
          part = div(diff, cols)

          max_column_lengths
          |> Map.new(fn {k, v} -> {k, v + part} end)
          |> then(fn map ->
            rest = rem(diff, cols)

            result =
              if rest > 0 do
                ordered_cols = Enum.map(columns, fn col -> {col, map[col]} end)
                {shorter_col, value} = Enum.min_by(ordered_cols, fn {_k, v} -> v end)
                Map.put(map, shorter_col, value + rest)
              else
                map
              end

            {title_len, result}
          end)
        else
          {column_lengths, max_column_lengths}
        end
      else
        {0, max_column_lengths}
      end

    junction = Keyword.fetch!(opts, :junction)
    line_sep = Keyword.fetch!(opts, :line_separator)

    vertical_divisor = [
      junction,
      Enum.map_intersperse(columns, junction, fn col ->
        cel_length = pad_left + pad_right + Map.fetch!(max_column_lengths, col)
        List.duplicate(line_sep, cel_length)
      end),
      junction
    ]

    outer_border = Keyword.fetch!(opts, :outer_border)
    blk_char = Keyword.fetch!(opts, :blank_space_char)

    title =
      if title_len > 0 do
        title = Keyword.fetch!(opts, :title)

        [
          outer_border,
          cell(
            {title, String.length(title)},
            title_len,
            pad_left,
            pad_right,
            blk_char,
            Keyword.fetch!(opts, :align_title)
          ),
          outer_border,
          ?\n,
          # This is following the columns sizes
          vertical_divisor,
          ?\n
        ]
      else
        []
      end

    normalized_header = Enum.map(columns, fn col -> Map.fetch!(columns_to_normalized, col) end)

    display_headers? = Keyword.fetch!(opts, :headers) != false

    headers =
      if display_headers? do
        header_line_sep = Keyword.fetch!(opts, :header_line_separator)
        align_headers = Keyword.fetch!(opts, :align_headers)

        [
          for line_columns <- header_lines(normalized_header) do
            [
              outer_border,
              Enum.map_intersperse(Enum.with_index(line_columns), col_sep, fn {col, idx} ->
                original_col_name = Enum.at(columns, idx)

                cell(
                  col,
                  Map.fetch!(max_column_lengths, original_col_name),
                  pad_left,
                  pad_right,
                  blk_char,
                  align_content(original_col_name, align_headers)
                )
              end),
              outer_border,
              ?\n
            ]
          end,
          [
            junction,
            Enum.map_intersperse(columns, junction, fn col ->
              cel_length = pad_left + pad_right + Map.fetch!(max_column_lengths, col)
              List.duplicate(header_line_sep, cel_length)
            end),
            junction,
            ?\n
          ]
        ]
      else
        []
      end

    align_content = Keyword.fetch!(opts, :align_content)

    maybe_vertical_divisor =
      if Keyword.fetch!(opts, :display_vertical_divisor) do
        [vertical_divisor, ?\n]
      else
        []
      end

    body =
      Enum.map_intersperse(normalized, maybe_vertical_divisor, fn row ->
        for line <- row_lines(row) do
          [
            outer_border,
            Enum.map_intersperse(columns, col_sep, fn col ->
              cell(
                Map.fetch!(line, col),
                Map.fetch!(max_column_lengths, col),
                pad_left,
                pad_right,
                blk_char,
                align_content(col, align_content)
              )
            end),
            outer_border,
            ?\n
          ]
        end
      end)

    top_border =
      if Keyword.fetch!(opts, :display_top_border) do
        if title_len > 0 do
          [
            junction,
            # This is following title size
            List.duplicate(line_sep, pad_left + pad_right + title_len),
            junction,
            ?\n
          ]
        else
          [
            vertical_divisor,
            ?\n
          ]
        end
      else
        []
      end

    bottom_border =
      if Keyword.fetch!(opts, :display_bottom_border) do
        [
          vertical_divisor,
          ?\n
        ]
      else
        []
      end

    {:ok, [top_border, title, headers, body, bottom_border]}
  end

  defp header_lines(normalized_columns) do
    max_height = normalized_columns |> Enum.map(&length/1) |> Enum.max()

    Enum.map(0..(max_height - 1)//1, fn idx ->
      Enum.map(normalized_columns, fn lines ->
        Enum.at(lines, idx, {"", 0})
      end)
    end)
  end

  defp row_lines(row) do
    max_height = row |> Map.values() |> Enum.map(&length/1) |> Enum.max()

    Enum.map(0..(max_height - 1)//1, fn idx ->
      Map.new(row, fn {k, v} -> {k, Enum.at(v, idx, {"", 0})} end)
    end)
  end

  # Maybe we want to assert that content is an IO data.
  defp cell(
         {content, len},
         max_column_len,
         padding_left,
         padding_right,
         blank_space_char,
         position
       ) do
    case position do
      :left ->
        [
          List.duplicate(blank_space_char, padding_left),
          content,
          List.duplicate(blank_space_char, max_column_len - len),
          List.duplicate(blank_space_char, padding_right)
        ]

      :right ->
        [
          List.duplicate(blank_space_char, padding_left),
          List.duplicate(blank_space_char, max_column_len - len),
          content,
          List.duplicate(blank_space_char, padding_right)
        ]

      :center ->
        spacing = div(max_column_len - len, 2)
        rest = rem(max_column_len - len, 2)

        [
          List.duplicate(blank_space_char, padding_left + spacing),
          content,
          List.duplicate(blank_space_char, padding_right + spacing + rest)
        ]
    end
  end

  defp align_content(_col, alignment) when is_atom(alignment), do: alignment

  defp align_content(col, alignments) when is_map(alignments),
    do: Map.get(alignments, col, :left)

  defp render_by_columns(reader, columns, normalized_columns, opts) do
    # OPTIMIZE: implement the traverse by columns.
    render_by_rows(reader, columns, normalized_columns, opts)
  end
end
