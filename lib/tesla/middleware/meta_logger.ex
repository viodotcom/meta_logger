defmodule Tesla.Middleware.MetaLogger do
  @moduledoc """
  Tesla middleware to log requests and responses.

  You can pass the options to the middleware or to the request `Tesla.Env`,
  env options takes precedence over middleware options.

  ## Example usage

    defmodule MyClient do
      use Tesla

      plug #{inspect(__MODULE__)},
        filter_headers: ["authorization"],
        log_level: :debug,
        log_tag: MyApp
    end

  ## Options

    * `:filter_headers` - The headers that should not be logged,
    the values will be replaced with `[FILTERED]`, defaults to: `[]`.
    * `:log_level` - The log level to be used, defaults to: `:info`. Responses with
    HTTP status 400 and above will be logged with `:error`, and redirect with `:warn`.
    * `:log_tag` - The log tag to be prefixed in the logs, default to: `#{inspect(__MODULE__)}`.

  """

  require Logger

  alias Tesla.{Env, Middleware}

  @behaviour Middleware

  @empty_values [nil, ""]

  @typep message :: String.t() | [String.t()] | nil | atom()

  @impl Middleware
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
    |> maybe_put_default_value(:filter_headers, [])
    |> maybe_put_default_value(:log_level, :info)
    |> maybe_put_default_value(:log_tag, __MODULE__)
  end

  @spec maybe_put_default_value(Env.opts(), atom(), any()) :: Env.opts()
  defp maybe_put_default_value(options, key, default_value),
    do: Keyword.put(options, key, Keyword.get(options, key, default_value))

  @spec log_request(Env.t(), Env.opts()) :: Env.t()
  defp log_request(%Env{body: body, method: method, query: query, url: url} = env, options) do
    level = Keyword.get(options, :log_level)
    headers = build_headers(env, options)

    log([format_method(method), url, inspect(query), inspect(headers)], level, options)
    log(body, level, options)

    env
  end

  @spec log_response(Env.result(), Env.opts()) :: Env.result()
  defp log_response({:ok, %Env{body: body, status: status} = env} = result, options) do
    level = response_log_level(result, options)
    headers = build_headers(env, options)

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

  @spec response_log_level(Env.result(), Env.opts()) :: Logger.level()
  defp response_log_level({:error, _any}, _options), do: :error
  defp response_log_level({:ok, %Env{status: status}}, _options) when status >= 400, do: :error
  defp response_log_level({:ok, %Env{status: status}}, _options) when status >= 300, do: :warn
  defp response_log_level(_result, options), do: Keyword.get(options, :log_level)

  @spec filter_header({String.t(), String.t()}, [String.t()]) :: {String.t(), String.t()}
  defp filter_header({key, _value} = header, filter_headers),
    do: if(key in filter_headers, do: {key, "[FILTERED]"}, else: header)

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
    tag =
      options
      |> Keyword.get(:log_tag)
      |> inspect()

    MetaLogger.log(level, Miss.String.build("[", tag, "] ", message))
  end

  defp log(message, level, options), do: log(inspect(message), level, options)
end
