defmodule FormatterProtocolTest do
  @moduledoc false
  @derive {MetaLogger.Formatter, formatter_fn: &__MODULE__.format/1, filter_patterns: ["bad"]}
  defstruct [:payload]

  def build(my_data) do
    struct!(__MODULE__, payload: my_data)
  end

  def format(%{be: be, to: to}) do
    [be, to]
  end
end
