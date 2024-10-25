defmodule MetaLogger.Slicer.Utf8ImplTest do
  use ExUnit.Case, async: true

  alias MetaLogger.Slicer.Utf8Impl, as: Subject

  doctest Subject

  describe "slice/2" do
    setup do
      entry = "0123456789"

      {:ok, entry: entry}
    end

    test "when `:infinity` is given as max entry length, returns a list with one entry", %{
      entry: entry
    } do
      assert Subject.slice(entry, :infinity) == [entry]
    end

    test "when max entry length is smaller than the size of given entry, " <>
           "returns a list with one entry",
         %{
           entry: entry
         } do
      assert Subject.slice(entry, 10) == ["0123456789"]
    end

    test "when max entry length is half the size of given entry, returns a list with two entries",
         %{
           entry: entry
         } do
      assert Subject.slice(entry, 5) == ["01234", "56789"]
    end

    test "when given max entry length is three and the given entry size is 10, " <>
           "returns a list with four entries",
         %{
           entry: entry
         } do
      assert Subject.slice(entry, 3) == ["012", "345", "678", "9"]
    end

    test "when an invalid max entry length is given, returns a list with one entry", %{
      entry: entry
    } do
      assert Subject.slice(entry, :pqp) == [entry]
    end

    test "when slicing a UTF-8 string all slices will be valid UTF-8 strings" do
      7..1
      |> Enum.each(fn max_length ->
        assert log_entries = Subject.slice("Hello 世界", max_length)
        assert Enum.all?(log_entries, &String.valid?/1)
      end)
    end
  end
end
