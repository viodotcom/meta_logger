defmodule MetaLogger do
  @moduledoc """
  A logger wrapper to keep logger metadata of caller processes.
  """

  require Logger

  @type chardata_or_fun :: IO.chardata() | String.Chars.t() | (any() -> any())
  @type metadata :: keyword()
  @metadata ~w(dictionary $logger_metadata$)a

  Enum.each(~w(debug error info warn)a, fn level ->
    @doc """
    Logs a #{level} message keeping logger metadata from caller processes.
    Returns `:ok` or an `{:error, reason}` tuple.

    ## Examples

        #{inspect(__MODULE__)}.#{level}("hello?")
        #{inspect(__MODULE__)}.#{level}(fn -> "dynamically calculated debug" end)
        #{inspect(__MODULE__)}.#{level}(fn -> {"dynamically calculated #{level}", [additional: :metadata]} end)

    """
    def unquote(level)(chardata_or_fun, metadata \\ []) do
      merge_logger_metadata_from_parent_processes()

      Logger.unquote(level)(chardata_or_fun, metadata)
    end
  end)

  @doc """
  Logs a message with given `level` keeping logger metadata from caller processes.

  Can accept a custom struct if it implements MetaLogger.Formatter protocol.

  Returns `:ok` or an `{:error, reason}` tuple.

  ## Examples

      #{inspect(__MODULE__)}.log(:info, "mission accomplished")
      #{inspect(__MODULE__)}.log(:error, fn -> "dynamically calculated info" end)
      #{inspect(__MODULE__)}.log(:warn, fn -> {"dynamically calculated info", [additional: :metadata]} end)

  """
  @spec log(atom(), struct() | list() | chardata_or_fun(), metadata()) :: :ok
  def log(level, payload, metadata \\ [])

  def log(level, data_struct, metadata) when is_struct(data_struct) do
    formatted_log = MetaLogger.Formatter.format(data_struct)

    log(level, formatted_log, metadata)
  end

  def log(level, logs, metadata) when is_atom(level) and is_list(logs),
    do: Enum.each(logs, &log(level, &1, metadata))

  def log(level, chardata_or_fun, metadata) when is_atom(level) do
    merge_logger_metadata_from_parent_processes()

    Logger.log(level, chardata_or_fun, metadata)
  end

  @spec merge_logger_metadata_from_parent_processes() :: :ok
  defp merge_logger_metadata_from_parent_processes do
    :"$callers"
    |> Process.get()
    |> List.wrap()
    |> Enum.each(&get_process_logger_metadata/1)
  end

  @spec get_process_logger_metadata(pid()) :: :ok
  defp get_process_logger_metadata(process) do
    process
    |> Process.info()
    |> get_in(@metadata)
    |> case do
      nil -> :ok
      metadata -> Logger.metadata(metadata)
    end
  end
end
