defmodule Tesla.Middleware.MetaLoggerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Tesla.Middleware.MetaLogger, as: Subject

  defmodule FakeClient do
    use Tesla

    plug Subject, filter_headers: ["authorization"], log_level: :debug, log_tag: Subject

    adapter fn env ->
      env =
        Tesla.put_headers(env, [
          {"content-type", "text/plain"},
          {"authorization", "somesecretthatshouldntbelogged"}
        ])

      case env.url do
        "/connection-error" ->
          {:error, :econnrefused}

        "/error" ->
          {:ok, %{env | status: 404, body: "error"}}

        "/redirect" ->
          {:ok, %{env | status: 301, body: "moved"}}

        "/ok" ->
          {:ok, %{env | status: 200, body: "ok"}}

        "/json" ->
          {:ok, %{env | status: 200, body: Jason.encode!(%{response: "value"})}}
      end
    end
  end

  describe "call/3" do
    test "logs the request and response" do
      logs = capture_log(fn -> FakeClient.get("/ok") end)

      assert logs =~ ~s([debug] [#{inspect(Subject)}] GET /ok [] [])

      assert logs =~
               "[debug] [#{inspect(Subject)}] 200 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[debug] [#{inspect(Subject)}] ok"
    end

    test "when log level is given, logs the message with given level" do
      logs = capture_log(fn -> FakeClient.post("/ok", %{}, opts: [log_level: :info]) end)

      assert logs =~ ~s([info]  [#{inspect(Subject)}] POST /ok [] [])

      assert logs =~
               "[info]  [#{inspect(Subject)}] 200 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[info]  [#{inspect(Subject)}] ok"
    end

    test "when a filtered header is given, logs the message filtering the given headers" do
      logs =
        capture_log(fn ->
          FakeClient.post("/ok", %{}, opts: [filter_headers: ["authorization", "content-type"]])
        end)

      assert logs =~ ~s([debug] [#{inspect(Subject)}] POST /ok [] [])

      assert logs =~
               ~s([debug] [#{inspect(Subject)}] 200 ) <>
                 ~s([{"content-type", "[FILTERED]"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[debug] [#{inspect(Subject)}] ok"
    end

    test "when response is an error, logs the response with error log level" do
      logs = capture_log(fn -> FakeClient.get("/error") end)

      assert logs =~ ~s([debug] [#{inspect(Subject)}] GET /error [] [])

      assert logs =~
               "[error] [#{inspect(Subject)}] 404 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[error] [#{inspect(Subject)}] error"
    end

    test "when response is a redirect, logs response with warn log level" do
      logs = capture_log(fn -> FakeClient.get("/redirect", opts: [log_level: :info]) end)

      assert logs =~ ~s([info]  [#{inspect(Subject)}] GET /redirect [] [])

      assert logs =~
               "[warn]  [#{inspect(Subject)}] 301 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[warn]  [#{inspect(Subject)}] moved"
    end

    test "when it fails to connect, logs the error" do
      logs = capture_log(fn -> FakeClient.get("/connection-error") end)

      assert logs =~ ~s([debug] [#{inspect(Subject)}] GET /connection-error [] [])
      assert logs =~ "[error] [#{inspect(Subject)}] :econnrefused"
    end

    test "when response body is a JSON, logs the message as a proper JSON" do
      encoded_body = Jason.encode!(%{something: 1})
      encoded_response = Jason.encode!(%{response: "value"})

      logs = capture_log(fn -> FakeClient.post("/json", encoded_body) end)

      assert logs =~ ~s([debug] [#{inspect(Subject)}] POST /json [] [])
      assert logs =~ "[debug] [#{inspect(Subject)}] #{encoded_body}"

      assert logs =~
               "[debug] [#{inspect(Subject)}] 200 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[debug] [#{inspect(Subject)}] #{encoded_response}"
    end
  end
end
