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
    code 400 and above will be logged with `:error`, and redirect with `:warn`.
    * `:log_tag` - The log tag to be prefixed in the logs. Defaults to the current module name.
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
    def call(%Env{opts: opts} = env, next, options) do
      options = prepare_options(options, opts)

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
    defp log_request(%Env{body: body, method: method, query: query, url: url} = env, options) do
      level = Keyword.get(options, :log_level)
      headers = build_headers(env, options)
      query = build_query(query, options)
      body = build_body(body, options)

      log([format_method(method), url, inspect(query), inspect(headers)], level, options)
      log(body, level, options)

      env
    end

    @spec log_response(Env.result(), Env.opts()) :: Env.result()
    defp log_response({:ok, %Env{body: body, status: status} = env} = result, options) do
      level = response_log_level(result, options)
      headers = build_headers(env, options)
      body = build_body(body, options)

      log([status, inspect(headers)], level, options)
      log(body, level, options)

      result
    end

    defp log_response({:error, reason} = result, options) do
      level = response_log_level(result, options)
      log(reason, level, options)

      result
    end

    @spec build_headers(Env.t(), Env.opts()) :: Env.headers()
    defp build_headers(%Env{headers: headers}, options) do
      filter_headers = Keyword.get(options, :filter_headers)
      Enum.map(headers, &filter_header(&1, filter_headers))
    end

    @spec filter_header({String.t(), String.t()}, [String.t()]) :: {String.t(), String.t()}
    defp filter_header({key, _value} = header, filter_headers),
      do: if(key in filter_headers, do: {key, @filtered}, else: header)

    @spec build_query(Env.query(), Env.opts()) :: Env.query()
    defp build_query(query, options) do
      filter_query_params = Keyword.get(options, :filter_query_params)
      Enum.map(query, &filter_query_params(&1, filter_query_params))
    end

    @spec filter_query_params({String.t() | atom(), String.t()}, [atom() | String.t()]) ::
            {atom() | String.t(), String.t()}
    defp filter_query_params({key, _value} = param, filter_query_params),
      do: if(key in filter_query_params, do: {key, @filtered}, else: param)

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
    defp response_log_level({:ok, %Env{status: status}}, _options) when status >= 300, do: :warn
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
        |> inspect()

      Miss.String.build("[", tag, "] ", message)
    end
  end
end
