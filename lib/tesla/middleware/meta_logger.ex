if Code.ensure_loaded?(Tesla) do
  defmodule Tesla.Middleware.MetaLogger do
    @moduledoc """
    Tesla middleware to log requests and responses.

    You can pass the options to the middleware or to the `Tesla.Env` request . The Tesla env
    options take precedence over the middleware options.

    ## Usage example

        defmodule MyClient do
          use Tesla

          plug #{inspect(__MODULE__)},
            filter_body: [{~r/"email":".*?"/, ~s("email":"[FILTERED]")}],
            filter_headers: ["authorization"],
            filter_query_params: [:api_key],
            log_level: :debug,
            log_tag: MyApp,
            max_entry_length: :infinity
        end

    ## Options

    * `:filter_headers` - The headers that should not be logged, the values will be replaced with
    `[FILTERED]`. Defaults to: `[]`.
    * `:filter_query_params` - The query params that should not be logged, the values will be
    replaced with `[FILTERED]`. Defaults to: `[]`.
    * `:filter_body` - The request and response body patterns that should not be logged, each
    filter can be just a pattern, wich will be replaced by `"[FILTERED]"`, or it can be a tuple
    with the pattern and the replacement. Because the body filtering is applied to strings it is
    necessary that this middleware is the last one on the stack, so it receives the request body
    already encoded and the response body not yet decoded. If the body is not a string, the
    filtering will be skipped.
    * `:log_level` - The log level to be used, defaults to: `:info`. Responses with HTTP status
    code 400 and above will be logged with `:error`, and redirect with `:warning`.
    * `:log_tag` - The log tag to be prefixed in the logs. Any non-string value will be inspect as
    a string. Defaults to the current module name.
    * `:max_entry_length` - The maximum length of a log entry before it is splitted into new ones.
    Defaults to `:infinity`.

    """

    require Logger

    alias MetaLogger.Slicer
    alias Tesla.{Env, Middleware}

    @behaviour Middleware

    @typep message :: String.t() | [String.t()] | nil | atom()

    @empty_values [nil, ""]
    @filtered "[FILTERED]"

    @impl true
    def call(%Env{} = env, next, options) do
      options = prepare_options(options, env.opts)

      env
      |> log_request(options)
      |> Tesla.run(next)
      |> log_response(options)
    end

    @spec prepare_options(Env.opts(), Env.opts()) :: Env.opts()
    defp prepare_options(middleware_options, env_options) do
      middleware_options
      |> Keyword.merge(env_options, fn _key, _middleware_value, env_value -> env_value end)
      |> maybe_put_default_values(~w(filter_body filter_headers filter_query_params)a, [])
      |> maybe_put_default_value(:log_level, :info)
      |> maybe_put_default_value(:log_tag, __MODULE__)
      |> maybe_put_default_value(:max_entry_length, :infinity)
    end

    @spec maybe_put_default_values(Env.opts(), [atom()], any()) :: Env.opts()
    defp maybe_put_default_values(options, keys, default_value),
      do: Enum.reduce(keys, options, &maybe_put_default_value(&2, &1, default_value))

    @spec maybe_put_default_value(Env.opts(), atom(), any()) :: Env.opts()
    defp maybe_put_default_value(options, key, default_value),
      do: Keyword.put(options, key, Keyword.get(options, key, default_value))

    @spec log_request(Env.t(), Env.opts()) :: Env.t()
    defp log_request(%Env{} = env, options) do
      method = format_method(env.method)
      url = build_url(env.url, env.query, options)
      headers = build_headers(env.headers, options)
      body = build_body(env.body, options)
      level = Keyword.get(options, :log_level)

      log([method, url, headers], level, options)
      log(body, level, options)

      env
    end

    @spec log_response(Env.result(), Env.opts()) :: Env.result()
    defp log_response({:ok, %Env{} = env} = result, options) do
      headers = build_headers(env.headers, options)
      body = build_body(env.body, options)
      level = response_log_level(result, options)

      log([env.status, headers], level, options)
      log(body, level, options)

      result
    end

    defp log_response({:error, reason} = result, options) do
      level = response_log_level(result, options)

      log(reason, level, options)

      result
    end

    @spec build_headers(Env.headers(), Env.opts()) :: String.t()
    defp build_headers(headers, options) do
      headers
      |> Enum.map(&filter_keyword(&1, Keyword.get(options, :filter_headers)))
      |> inspect()
    end

    @spec build_url(Env.url(), Env.query(), Env.opts()) :: String.t()
    defp build_url(url, query, options) do
      encoded_query =
        query
        |> Enum.map(&filter_keyword(&1, Keyword.get(options, :filter_query_params)))
        |> URI.encode_query()
        |> URI.decode()

      if encoded_query == "" do
        url
      else
        Miss.String.build(url, "?", encoded_query)
      end
    end

    @spec filter_keyword({atom() | String.t(), String.t()}, [atom()] | [String.t()]) ::
            {atom() | String.t(), String.t()}
    defp filter_keyword({key, _value} = item, filters),
      do: if(key in filters, do: {key, @filtered}, else: item)

    @spec build_body(Env.body(), Env.opts()) :: Env.body()
    defp build_body(body, options) when is_binary(body) do
      options
      |> Keyword.get(:filter_body)
      |> Enum.reduce(body, &filter_body(&2, &1))
    end

    defp build_body(body, _options), do: body

    @spec filter_body(Env.body(), {Regex.t(), String.t()} | Regex.t()) :: Env.body()
    defp filter_body(body, {pattern, replacement}), do: String.replace(body, pattern, replacement)
    defp filter_body(body, pattern), do: String.replace(body, pattern, @filtered)

    @spec response_log_level(Env.result(), Env.opts()) :: Logger.level()
    defp response_log_level({:error, _any}, _options), do: :error
    defp response_log_level({:ok, %Env{status: status}}, _options) when status >= 400, do: :error

    defp response_log_level({:ok, %Env{status: status}}, _options) when status >= 300,
      do: :warning

    defp response_log_level(_result, options), do: Keyword.get(options, :log_level)

    @spec format_method(atom()) :: String.t()
    defp format_method(method) do
      method
      |> to_string()
      |> String.upcase()
    end

    @spec log(message(), Logger.level(), Env.opts()) :: :ok
    defp log(message, _level, _options) when message in @empty_values, do: :ok

    defp log(message, level, options) when is_list(message) do
      message
      |> Enum.join(" ")
      |> log(level, options)
    end

    defp log(message, level, options) when is_binary(message) do
      max_entry_length = Keyword.get(options, :max_entry_length)

      message
      |> Slicer.slice(max_entry_length)
      |> Enum.map(&prepend_tag(&1, options))
      |> Enum.each(&MetaLogger.log(level, &1))
    end

    defp log(message, level, options), do: log(inspect(message), level, options)

    @spec prepend_tag(String.t(), Env.opts()) :: String.t()
    defp prepend_tag(message, options) do
      tag =
        options
        |> Keyword.get(:log_tag)
        |> case do
          tag when is_binary(tag) -> tag
          tag -> inspect(tag)
        end

      Miss.String.build("[", tag, "] ", message)
    end
  end
end
