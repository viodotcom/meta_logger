defmodule MetaLogger.Slicer do
  @moduledoc """
  A bebaviour for slicing long entries into a list of entries shorter than a passed `max_entry_length` value.
  """

  @typedoc "Max length in bytes or `:infinity` if the entry should not be sliced."
  @type max_entry_length :: non_neg_integer() | :infinity
  @callback slice(binary(), max_entry_length()) :: [binary()]
end
