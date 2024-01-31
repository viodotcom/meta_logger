defmodule Tesla.Middleware.MetaLoggerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Tesla.Middleware.MetaLogger, as: Subject

  defmodule FakeClient do
    use Tesla

    plug Subject,
      filter_headers: ["authorization"],
      filter_query_params: [:username],
      filter_body: [{~r/"email":".*?"/, ~s("email":"[FILTERED]")}],
      log_level: :debug,
      log_tag: Subject

    @response_headers [
      {"content-type", "text/plain"},
      {"authorization", "somesecretthatshouldntbelogged"}
    ]

    adapter(fn env ->
      case env.url do
        "/connection-error" ->
          {:error, :econnrefused}

        "/ok" ->
          {:ok, FakeClient.put_response(env, 200, "response body ok")}

        "/huge-response" ->
          {:ok,
           FakeClient.put_response(
             env,
             200,
             String.duplicate("a", 100) <> String.duplicate("b", 100)
           )}

        "/json" ->
          {:ok, FakeClient.put_response(env, 200, ~s({"email":"foo@bar.baz","response":"value"}))}

        "/redirect" ->
          {:ok, FakeClient.put_response(env, 301, "response body moved")}

        "/error" ->
          {:ok, FakeClient.put_response(env, 404, "response body error")}
      end
    end)

    def put_response(env, status, body),
      do: %{env | status: status, headers: @response_headers, body: body}
  end

  describe "call/3" do
    test "logs the request and the response" do
      logs =
        capture_log(fn ->
          FakeClient.get("/ok",
            headers: [{"accept", "text/plain"}],
            query: [page: 1, username: "test_user"]
          )
        end)

      assert logs =~
               "[debug] [#{inspect(Subject)}] GET /ok?page=1&username=[FILTERED] " <>
                 ~s([{"accept", "text/plain"}])

      assert logs =~
               "[debug] [#{inspect(Subject)}] 200 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[debug] [#{inspect(Subject)}] response body ok"
    end

    test "when the request body is given, logs the request and the response" do
      logs =
        capture_log(fn ->
          FakeClient.post("/json", ~s({"email":"foo@bar.baz","some":"body"}),
            headers: [{"accept", "application/json"}]
          )
        end)

      assert logs =~
               ~s([debug] [#{inspect(Subject)}] POST /json [{"accept", "application/json"}])

      assert logs =~ ~s([debug] [#{inspect(Subject)}] {"email":"[FILTERED]","some":"body"})

      assert logs =~
               "[debug] [#{inspect(Subject)}] 200 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ ~s([debug] [#{inspect(Subject)}] {"email":"[FILTERED]","response":"value"})
    end

    test "when query string and request body are given, logs the request and the response" do
      logs =
        capture_log(fn ->
          FakeClient.post("/json", ~s({"email":"foo@bar.baz","some":"body"}),
            headers: [{"accept", "application/json"}],
            query: [page: 1, username: "test_user"]
          )
        end)

      assert logs =~
               "[debug] [#{inspect(Subject)}] " <>
                 ~s(POST /json?page=1&username=[FILTERED] [{"accept", "application/json"}])

      assert logs =~ ~s([debug] [#{inspect(Subject)}] {"email":"[FILTERED]","some":"body"})

      assert logs =~
               "[debug] [#{inspect(Subject)}] 200 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ ~s([debug] [#{inspect(Subject)}] {"email":"[FILTERED]","response":"value"})
    end

    test "when the log tag is given as a string, logs using the log tag without inspecting" do
      logs = capture_log(fn -> FakeClient.get("/ok", opts: [log_tag: "MOOI"]) end)

      assert logs =~ "[debug] [MOOI] GET /ok"

      assert logs =~
               "[debug] [MOOI] 200 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[debug] [MOOI] response body ok"
    end

    test "when the log tag is given as not a string, logs using the log tag inspecting" do
      logs = capture_log(fn -> FakeClient.get("/ok", opts: [log_tag: FakeClient]) end)

      assert logs =~ "[debug] [#{inspect(FakeClient)}] GET /ok []"

      assert logs =~
               "[debug] [#{inspect(FakeClient)}] 200 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[debug] [#{inspect(FakeClient)}] response body ok"
    end

    test "when the log level is given, logs the message with the given log level" do
      logs = capture_log(fn -> FakeClient.get("/ok", opts: [log_level: :info]) end)

      assert logs =~ "[info] [#{inspect(Subject)}] GET /ok []"

      assert logs =~
               "[info] [#{inspect(Subject)}] 200 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[info] [#{inspect(Subject)}] response body ok"
    end

    test "when a filtered header is given, logs the message filtering the given headers" do
      logs =
        capture_log(fn ->
          FakeClient.get("/ok", opts: [filter_headers: ["authorization", "content-type"]])
        end)

      assert logs =~ "[debug] [#{inspect(Subject)}] GET /ok []"

      assert logs =~
               "[debug] [#{inspect(Subject)}] 200 " <>
                 ~s([{"content-type", "[FILTERED]"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[debug] [#{inspect(Subject)}] response body ok"
    end

    test "when a filtered query param is given, logs the message filtering the given query params" do
      logs =
        capture_log(fn ->
          FakeClient.get("/ok",
            query: [{:page, 1}, {:user, "test_user"}, {"password", "test password"}],
            opts: [filter_query_params: [:user, "password"]]
          )
        end)

      assert logs =~
               "[debug] [#{inspect(Subject)}] " <>
                 "GET /ok?page=1&user=[FILTERED]&password=[FILTERED] []"

      assert logs =~
               "[debug] [#{inspect(Subject)}] 200 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[debug] [#{inspect(Subject)}] response body ok"
    end

    test "when a filtered body is given, logs the message filtering the given request body" do
      logs =
        capture_log(fn ->
          FakeClient.post("/json", ~s({"password":"0123456789","some":"body"}),
            opts: [filter_body: [~r/"password":".*?"/]]
          )
        end)

      assert logs =~ "[debug] [#{inspect(Subject)}] POST /json []"
      assert logs =~ ~s([debug] [#{inspect(Subject)}] {[FILTERED],"some":"body"})

      assert logs =~
               "[debug] [#{inspect(Subject)}] 200 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ ~s([debug] [#{inspect(Subject)}] {"email":"foo@bar.baz","response":"value"})
    end

    test "when the max entry length is given, " <>
           "logs the request and the response splitting the body" do
      request_body_slice1 = String.duplicate("x", 100)
      request_body_slice2 = String.duplicate("y", 100)

      logs =
        capture_log(fn ->
          FakeClient.post("/huge-response", request_body_slice1 <> request_body_slice2,
            opts: [max_entry_length: 100]
          )
        end)

      assert logs =~ "[debug] [#{inspect(Subject)}] POST /huge-response []"
      assert logs =~ "[debug] [#{inspect(Subject)}] #{request_body_slice1}\n"
      assert logs =~ "[debug] [#{inspect(Subject)}] #{request_body_slice2}\n"

      assert logs =~
               "[debug] [#{inspect(Subject)}] 200 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[debug] [#{inspect(Subject)}] #{String.duplicate("a", 100)}\n"
      assert logs =~ "[debug] [#{inspect(Subject)}] #{String.duplicate("b", 100)}\n"
    end

    test "when response is an error, logs the response with error log level" do
      logs = capture_log(fn -> FakeClient.get("/error") end)

      assert logs =~ "[debug] [#{inspect(Subject)}] GET /error []"

      assert logs =~
               "[error] [#{inspect(Subject)}] 404 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[error] [#{inspect(Subject)}] response body error"
    end

    test "when response is a redirect, logs response with warning log level" do
      logs = capture_log(fn -> FakeClient.get("/redirect", opts: [log_level: :info]) end)

      assert logs =~ "[info] [#{inspect(Subject)}] GET /redirect []"

      assert logs =~
               "[warning] [#{inspect(Subject)}] 301 " <>
                 ~s([{"content-type", "text/plain"}, {"authorization", "[FILTERED]"}])

      assert logs =~ "[warning] [#{inspect(Subject)}] response body moved"
    end

    test "when the request fails to connect, logs the error" do
      logs = capture_log(fn -> FakeClient.get("/connection-error") end)

      assert logs =~ "[debug] [#{inspect(Subject)}] GET /connection-error []"
      assert logs =~ "[error] [#{inspect(Subject)}] :econnrefused"
    end
  end
end
