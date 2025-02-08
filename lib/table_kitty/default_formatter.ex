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
defmodule TableKitty.DefaultFormatter do
  @moduledoc """
  The default formatter that can display Elixir terms.
  """

  @doc """
  The default format function.

  It receives a map that has a `:context` field,
  a `:value`, and may have more keys.
  """
  @spec format(map(), Keyword.t()) :: String.t()
  def format(context, _opts) do
    context
    |> Map.fetch!(:value)
    |> do_format(1)
  end

  # Beginning of formatting function copied from Explorer.
  # Authors: the Explorer developers.
  # Version: v0.10.1
  # License: MIT - https://github.com/elixir-explorer/explorer/blob/v0.10.1/LICENSE
  # Source code: https://github.com/elixir-explorer/explorer/blob/1ca086da8ae70ba86b19cc69c1114b0be96073f4/lib/explorer/data_frame.ex#L6004
  # Date of copy: 2025-02-08
  # Original function name: `format_column/2` (private)

  defp do_format(list, depth) when is_list(list) do
    list
    |> Enum.map(&do_format(&1, depth + 1))
    |> multiline(depth, "[", "]")
  end

  # TODO: Use is_non_struct_map when we require Elixir v1.17+
  defp do_format(map, depth) when is_map(map) and not is_struct(map) do
    map
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.map(fn {k, v} -> "#{k}: #{do_format(v, depth + 1)}" end)
    |> multiline(depth, "{", "}")
  end

  defp do_format(value, depth) do
    cond do
      is_nil(value) ->
        "nil"

      is_binary(value) and not String.valid?(value) ->
        value
        |> :binary.bin_to_list()
        |> Enum.map(&Kernel.to_string/1)
        |> multiline(depth, "<<", ">>")

      true ->
        to_string(value)
    end
  end

  defp multiline(contents, depth, left, right) do
    indent = String.duplicate(" ", max(depth - 1, 0))

    if length(contents) > 1 or Enum.any?(contents, &String.contains?(&1, "\n")) do
      "#{left}\n #{indent}#{Enum.join(contents, "\n " <> indent)}\n#{indent}#{right}"
    else
      "#{left}#{contents}#{right}"
    end
  end

  # End of formatting function copied from Explorer.
end
