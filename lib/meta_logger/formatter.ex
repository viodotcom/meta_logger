defprotocol MetaLogger.Formatter do
  @doc """
  MetaLogger formatter protocol.
  """
  @fallback_to_any true

  @spec format(struct()) :: String.t() | list()
  def format(payload)

  defmodule IncorrectPayload do
    defexception [:message]
  end

  defmodule IncorrectOrNotSetFormatterFunction do
    defexception [:message]
  end
end

defimpl MetaLogger.Formatter, for: Any do
  @moduledoc """
  Default implementation for any struct which used to be derived.
  """
  defmacro __deriving__(module, _struct, options) do
    formatter_func = fetch_formatter_function(options)

    quote do
      defimpl MetaLogger.Formatter, for: unquote(module) do
        @replacement "[FILTERED]"

        def format(struct) do
          formatter_fn = Keyword.fetch!(unquote(options), :formatter_fn)

          struct
          |> Map.get(:payload)
          |> safe_func_invoke()
          |> filter()
        end

        defp filter(payload) when is_list(payload),
          do: Enum.map(payload, &filter(&1))

        defp filter(payload) when is_bitstring(payload) do
          Keyword.get(unquote(options), :filter_patterns)
          |> filter(payload)
        end

        defp filter(patterns, payload) do
          Enum.reduce(patterns, payload, fn pattern, payload ->
            String.replace(payload, ~r/#{pattern}/, @replacement)
          end)
        end

        defp safe_func_invoke(args) do
          unquote(Macro.escape(formatter_func)).(args)
        rescue
          FunctionClauseError ->
            reraise MetaLogger.Formatter.IncorrectPayload,
                    [
                      message:
                        "Given formatter function doesn't accept a payload: #{inspect(args)}"
                    ],
                    __STACKTRACE__
        end
      end
    end
  end

  def format(struct) do
    raise Protocol.UndefinedError,
      protocol: @protocol,
      value: struct,
      description: """
      MetaLogger.Formatter protocol must always be explicitly implemented.
      You need to define your own struct and derive `MetaLogger.Formatter` with `formatter_fn` and `filter_patterns` options.
      The struct must have `payload` field which is given format function receives.
      Derive arguments:
        - `formatter_fn` is a function, which accepts payload. Returns bitstring or a list.
        - `filter_patterns` is a list of patterns that will be used for regexp what should be filtered (replaced)

      Example of usage:
          @derive {MetaLogger.Formatter, formatter_fn: &Module.func/1, filter_patterns: [~s("email":".*")]}
          defstruct ...

      """
  end

  defp fetch_formatter_function(options) do
    case Keyword.fetch(options, :formatter_fn) do
      {:ok, function} ->
        function

      :error ->
        raise MetaLogger.Formatter.IncorrectOrNotSetFormatterFunction,
          message:
            "Formatter function must be provided, e.g. @derive {MetaLogger.Formatter, formatter_fn: &__MODULE__.format/1}"
    end
  end
end
