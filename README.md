# Table Kitty

A library to generate text-based tables in Elixir.

It's similar to [`TableRex`](https://github.com/djm/table_rex), but
most of the API is based on options for the `TableKitty.build/2` function.

The tabular data must implement the `Table.Reader` protocol. This is already
available for data that is a map of columns or a list of rows (list of maps).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `table_kitty` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:table_kitty, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/table_kitty>.

## License

Copyright (C) 2025 Philip Sampaio Silva

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
