defmodule FormatterProtocolTest do
  @moduledoc false
  @filter_patterns [
    "bad",
    {~s/"name":".*"/, ~s/"name":"[FILTERED]"/}
  ]
  @derive {MetaLogger.Formatter,
           formatter_fn: &__MODULE__.format/1, filter_patterns: @filter_patterns}
  defstruct [:payload]

  def build(my_data) do
    struct!(__MODULE__, payload: my_data)
  end

  def format(%{be: be, to: to}) do
    [be, to]
  end
end
