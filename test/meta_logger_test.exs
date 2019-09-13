defmodule MetaLoggerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias MetaLogger, as: Subject

  setup do
    Logger.configure_backend(:console, metadata: [:foo, :bar, :baz])

    on_exit(fn -> Logger.configure_backend(:console, metadata: []) end)
  end

  ~w(debug error info warn)a
  |> Enum.each(fn level ->
    describe "#{level}/2" do
      test "logs a message with #{level} level and metadata from current and caller processes" do
        Logger.metadata(foo: "foo")

        logs =
          capture_log(fn ->
            Task.async(fn ->
              Logger.metadata(bar: "bar")

              Task.async(fn ->
                Logger.metadata(baz: "baz")

                Subject.unquote(level)("test")
              end)
              |> Task.await()
            end)
            |> Task.await()
          end)

        assert logs =~ "foo=foo bar=bar baz=baz [#{unquote(level)}]"
        assert logs =~ "test"
      end
    end
  end)

  describe "log/3" do
    ~w(debug error info warn)a
    |> Enum.each(fn level ->
      test "logs a message with #{level} level and metadata from current and caller processes" do
        Logger.metadata(foo: "baz")

        logs =
          capture_log(fn ->
            Task.await(
              Task.async(fn ->
                Logger.metadata(bar: "foo")

                Task.await(
                  Task.async(fn ->
                    Logger.metadata(baz: "bar")

                    Subject.log(unquote(level), "test")
                  end)
                )
              end)
            )
          end)

        assert logs =~ "foo=baz bar=foo baz=bar [#{unquote(level)}]"
        assert logs =~ "test"
      end
    end)
  end
end
