defmodule MetaLoggerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias MetaLogger, as: Subject

  ~w(debug error info warning)a
  |> Enum.each(fn level ->
    describe "#{level}/2" do
      test "logs a message with #{level} level and metadata from current and caller processes" do
        Logger.metadata(foo: "foo")

        logs =
          capture_log(fn ->
            Task.await(
              Task.async(fn ->
                Logger.metadata(bar: "bar")

                Task.await(
                  Task.async(fn ->
                    Logger.metadata(baz: "baz")

                    Subject.unquote(level)("test")
                  end)
                )
              end)
            )
          end)

        assert logs =~ "bar=bar baz=baz foo=foo [#{unquote(level)}] test"
      end

      test "when logger metadata key is set to nil, logs a message with #{level} and no metadata" do
        Process.put("$logger_metadata$", nil)

        logs =
          capture_log(fn ->
            Task.await(
              Task.async(fn ->
                Process.put("$logger_metadata$", nil)

                Task.await(
                  Task.async(fn ->
                    Process.put("$logger_metadata$", nil)

                    Subject.unquote(level)("test")
                  end)
                )
              end)
            )
          end)

        assert logs =~ "[#{unquote(level)}]"
        assert logs =~ "test"
      end
    end
  end)

  describe "warn/2" do
    test "logs a message with warning level and metadata from current and caller processes" do
      Logger.metadata(foo: "foo")

      logs =
        capture_log(fn ->
          Task.await(
            Task.async(fn ->
              Logger.metadata(bar: "bar")

              Task.await(
                Task.async(fn ->
                  Logger.metadata(baz: "baz")
                  Subject.warn("test")
                end)
              )
            end)
          )
        end)

      assert logs =~ "bar=bar baz=baz foo=foo [warning] test"
    end

    test "when logger metadata key is set to nil, logs a message with warning and no metadata" do
      Process.put("$logger_metadata$", nil)

      logs =
        capture_log(fn ->
          Task.await(
            Task.async(fn ->
              Process.put("$logger_metadata$", nil)

              Task.await(
                Task.async(fn ->
                  Process.put("$logger_metadata$", nil)

                  Subject.warn("test")
                end)
              )
            end)
          )
        end)

      assert logs =~ "[warning]"
      assert logs =~ "test"
    end
  end

  describe "log/3" do
    ~w(debug error info warning)a
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

        assert logs =~ "bar=foo baz=bar foo=baz [#{unquote(level)}]"
        assert logs =~ "test"
      end

      test "when logger metadata key is set to nil, logs a message with #{level} and no metadata" do
        Process.put("$logger_metadata$", nil)

        logs =
          capture_log(fn ->
            Task.await(
              Task.async(fn ->
                Process.put("$logger_metadata$", nil)

                Task.await(
                  Task.async(fn ->
                    Process.put("$logger_metadata$", nil)

                    Subject.log(unquote(level), "test")
                  end)
                )
              end)
            )
          end)

        assert logs =~ "[#{unquote(level)}]"
        assert logs =~ "test"
      end
    end)
  end

  describe "metadata/0" do
    test "returns the logger metadata from the current process and caller processes" do
      Logger.metadata(foo: "baz")

      Task.await(
        Task.async(fn ->
          Logger.metadata(bar: "foo")

          Task.await(
            Task.async(fn ->
              Logger.metadata(baz: "bar")

              assert Subject.metadata() == [foo: "baz", bar: "foo", baz: "bar"]
            end)
          )
        end)
      )
    end

    test "when logger metadata key is set to nil, returns an empty list" do
      Process.put("$logger_metadata$", nil)

      Task.await(
        Task.async(fn ->
          Process.put("$logger_metadata$", nil)

          Task.await(
            Task.async(fn ->
              Process.put("$logger_metadata$", nil)

              assert Logger.metadata() == []
            end)
          )
        end)
      )
    end

    test "when the logger metadata is empty, returns an empty list" do
      assert Logger.metadata() == []
    end
  end

  describe "MetaLogger Formatter" do
    test "logs a given data using formatter implementation" do
      my_struct = FormatterProtocolTest.build(%{be: "good", to: "the world"})

      logs =
        capture_log(fn ->
          Subject.log(:info, my_struct)
        end)

      assert logs =~ "good"
      assert logs =~ "the world"
    end
  end
end
