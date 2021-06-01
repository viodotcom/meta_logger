defmodule MetaLogger.FormatterTest do
  use ExUnit.Case

  alias MetaLogger.Formatter, as: Subject

  setup do
    Logger.configure_backend(:console, metadata: [:foo, :bar, :baz])

    on_exit(fn -> Logger.configure_backend(:console, metadata: []) end)
  end

  test "accpets a correct struct and returns a formatted data" do
    formatted_log =
      %{be: "good", to: "the world"}
      |> FormatterProtocolTest.build()
      |> Subject.format()

    assert formatted_log == ["good", "the world"]
  end

  test "filters elements by a given pattern" do
    formatted_log =
      FormatterProtocolTest.build(%{be: "bad", to: "the world"})
      |> Subject.format()

    assert formatted_log == ["[FILTERED]", "the world"]
  end

  test "raises an error when there is wrong struct given" do
    defmodule WrongStruct do
      defstruct [:a]
    end

    assert_raise(Protocol.UndefinedError, fn ->
      Subject.format(WrongStruct)
    end)
  end

  test "raises the error when a payload for format function is incorrect" do
    defmodule IncorrectStruct do
      @derive {Subject, formatter_fn: &__MODULE__.format/1}
      defstruct [:payload]
      def format(%{b: b}), do: b
    end

    my_struct = struct!(IncorrectStruct, payload: %{a: "1"})

    assert_raise(MetaLogger.Formatter.IncorrectPayload, fn ->
      Subject.format(my_struct)
    end)
  end

  test "raises the error when formatter function is not set" do
    assert_raise(MetaLogger.Formatter.IncorrectOrNotSetFormatterFunction, fn ->
      defmodule IncorrectDerivedStruct do
        @derive Subject
        defstruct [:payload]
      end
    end).message =~
      "Formatter function must be provided, e.g. @derive {MetaLogger.Formatter, formatter_fn: &__MODULE__.format/1}"
  end
end
