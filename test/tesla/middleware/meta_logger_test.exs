defmodule Tesla.Middleware.MetaLoggerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Tesla.Middleware.MetaLogger, as: Subject

  defmodule FakeClient do
    use Tesla

    plug(Subject,
      filter_headers: ["authorization"],
      filter_query_params: [:username],
      filter_body: [{~r/"email":".*?"/, ~s("email":"[FILTERED]")}],
      log_level: :debug,
      log_tag: Subject
    )

    adapter(fn env ->
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
          {:ok, %{env | status: 200, body: ~s({"email":"foo@bar.baz","response":"value"})}}
      end
    end)
  end

  describe "call/3" do
    test "logs the request and response" do
      logs = capture_log(fn -> FakeClient.get("/ok", query: [page: 1, username: "test_user"]) end)

      assert logs =~
               ~s([debug] [#{inspect(Subject)}] GET /ok [page: 1, username: "[FILTERED]"] [])

      assert logs =~
               "[debug] [#{inspect(Subject)}] 200 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[debug] [#{inspect(Subject)}] ok"
    end

    test "when body is given logs the request and response" do
      logs = capture_log(fn -> FakeClient.post("/json", ~s({"email":"foo@bar.baz"})) end)

      assert logs =~
               ~s([debug] [#{inspect(Subject)}] POST /json [] [])

      assert logs =~ ~s([debug] [#{inspect(Subject)}] {"email":"[FILTERED]"})

      assert logs =~
               "[debug] [#{inspect(Subject)}] 200 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ ~s([debug] [#{inspect(Subject)}] {"email":"[FILTERED]","response":"value"})
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

    test "when a filtered query param is given, logs the message filtering the given query param" do
      logs =
        capture_log(fn ->
          FakeClient.post("/ok", %{},
            query: [{:page, 1}, {:user, "test_user"}, {"password", "test password"}],
            opts: [filter_query_params: [:user, "password"]]
          )
        end)

      assert logs =~
               ~s([debug] [#{inspect(Subject)}] POST /ok [{:page, 1}, {:user, "[FILTERED]"}, ) <>
                 ~s({"password", "[FILTERED]"}] [])

      assert logs =~
               ~s([debug] [#{inspect(Subject)}] 200 ) <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[debug] [#{inspect(Subject)}] ok"
    end

    test "when a filtered body is given, logs the message filtering the given body patterns" do
      logs =
        capture_log(fn ->
          FakeClient.post("/json", ~s({"password":"0123456789","somethingsafe":"ok"}),
            opts: [filter_body: [~r/"password":".*?"/]]
          )
        end)

      assert logs =~
               ~s([debug] [#{inspect(Subject)}] POST /json [] [])

      assert logs =~ ~s([debug] [#{inspect(Subject)}] {[FILTERED],"somethingsafe":"ok"})

      assert logs =~
               ~s([debug] [#{inspect(Subject)}] 200 ) <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ ~s([debug] [#{inspect(Subject)}] {"email":"foo@bar.baz","response":"value"})
    end

    test "when max entry length is given, " <>
           "logs the request and response splitting the entries" do
      body_prefix = String.duplicate("a", 80)

      logs =
        capture_log(fn ->
          FakeClient.post("/json", body_prefix <> "b", opts: [max_entry_length: 80])
        end)

      assert logs =~
               ~s([debug] [#{inspect(Subject)}] POST /json [] [])

      assert logs =~ ~s([debug] [#{inspect(Subject)}] #{body_prefix}\n)
      assert logs =~ ~s([debug] [#{inspect(Subject)}] b\n)

      assert logs =~
               "[debug] [#{inspect(Subject)}] 200 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ ~s([debug] [#{inspect(Subject)}] {"email":"[FILTERED]","response":"value"})
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

      logs = capture_log(fn -> FakeClient.post("/json", encoded_body) end)

      assert logs =~ ~s([debug] [#{inspect(Subject)}] POST /json [] [])
      assert logs =~ "[debug] [#{inspect(Subject)}] #{encoded_body}"

      assert logs =~
               "[debug] [#{inspect(Subject)}] 200 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ ~s([debug] [#{inspect(Subject)}] {"email":"[FILTERED]","response":"value"})
    end
  end
end
