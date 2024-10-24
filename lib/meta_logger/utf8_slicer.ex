defmodule MetaLogger.Slicer.Utf8Impl do
  @moduledoc """
  Slices a string into chunks of a given length, taking into account the UTF-8 encoding of the string.
  """

  @behaviour MetaLogger.Slicer

  @typedoc "Max length in bytes or `:infinity` if the entry should not be sliced."
  @type max_entry_length :: non_neg_integer() | :infinity

  @doc """
  Returns sliced log entries according to the given max entry length.

  Ensures that all slices are valid UTF-8 strings by not splitting multibyte characters.
  If the entry is smaller than the given max length, or if `:infinity` is given
  as an option, a list with one entry is returned. Otherwise, a list with multiple
  entries is returned.

  ## Examples

      iex> #{inspect(__MODULE__)}.slice("1234567890", 10)
      ["1234567890"]

      iex> #{inspect(__MODULE__)}.slice("1234567890", :infinity)
      ["1234567890"]

      iex> #{inspect(__MODULE__)}.slice("1234567890", 5)
      ["12345", "67890"]

      iex> #{inspect(__MODULE__)}.slice("Hello 世界", 7)
      ["Hello ", "世界"]
  """
  @impl MetaLogger.Slicer
  @spec slice(String.t(), integer()) :: [String.t()]
  def slice(log_entry, :infinity), do: [log_entry]

  def slice(entry, max_entry_length) when byte_size(entry) <= max_entry_length,
    do: [entry]

  def slice(entry, max_entry_length) do
    do_slice(entry, max_entry_length, [], [], 0)
  end

  @spec do_slice(binary(), integer(), [binary()], [iodata()], integer()) :: [binary()]
  defp do_slice(<<>>, _max_length, slices, partial_slice, _partial_size) do
    # The remaining log entry is empty so we clean up the last partial_slice
    # and return the slices.
    partial_slice
    |> case do
      [] -> slices
      _ -> bank_partial_slice(slices, partial_slice)
    end
    |> Enum.reverse()
  end

  defp do_slice(
         <<codepoint::utf8, rest::binary>>,
         max_length,
         slices,
         partial_slice,
         partial_size
       ) do
    codepoint_binary = <<codepoint::utf8>>
    codepoint_size = byte_size(codepoint_binary)
    new_size = partial_size + codepoint_size

    if new_size <= max_length do
      # There is still room in the partial_slice for more codepoints
      # so we prepend (to later reverse) the codepoint binary
      # and consider the next codepoint.
      do_slice(rest, max_length, slices, [codepoint_binary | partial_slice], new_size)
    else
      # Adding the new codepoint to the partial slice puts it over the limit
      # So we bank the partial slice and start the codepoint as the new partial_slice
      slices = bank_partial_slice(slices, partial_slice)
      new_partial_slice = [codepoint_binary]
      do_slice(rest, max_length, slices, new_partial_slice, codepoint_size)
    end
  end

  # Converts the inverted list of codepoints into a
  # binary slice and appends it to our list of slices.
  @spec bank_partial_slice([binary()], [iodata()]) :: [binary()]
  defp bank_partial_slice(slices, partial_slice) do
    [reconstruct_current_slice_as_binary(partial_slice) | slices]
  end

  @spec reconstruct_current_slice_as_binary([iodata()]) :: binary()
  defp reconstruct_current_slice_as_binary(current_slice) do
    IO.iodata_to_binary(Enum.reverse(current_slice))
  end
end
