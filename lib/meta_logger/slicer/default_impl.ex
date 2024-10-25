defmodule MetaLogger.Slicer.DefaultImpl do
  @moduledoc """
  Responsible for slicing log entries according to the given max length option.
  """

  @behaviour MetaLogger.Slicer
  
  @doc """
  Returns sliced log entries according to the given max entry length.

  If the entry is smaller than given max length, or if `:infinity ` is given
  as option, a list with one entry is returned. Otherwise a list with multiple
  entries is returned.

  ## Examples

      iex> #{inspect(__MODULE__)}.slice("1234567890", 10)
      ["1234567890"]

      iex> #{inspect(__MODULE__)}.slice("1234567890", :infinity)
      ["1234567890"]

      iex> #{inspect(__MODULE__)}.slice("1234567890", 5)
      ["12345", "67890"]

  """
  @impl MetaLogger.Slicer
  @spec slice(binary(), MetaLogger.Slicer.max_entry_length()) :: [binary()]
  def slice(entry, max_entry_length)
      when max_entry_length == :infinity
      when byte_size(entry) <= max_entry_length,
      do: [entry]

  def slice(entry, max_entry_length) do
    entry_length = byte_size(entry)
    rem = rem(entry_length, max_entry_length)
    sliced_entries = for <<slice::binary-size(max_entry_length) <- entry>>, do: slice

    if rem > 0 do
      remainder_entry = binary_part(entry, entry_length, rem * -1)
      sliced_entries ++ [remainder_entry]
    else
      sliced_entries
    end
  end
end
