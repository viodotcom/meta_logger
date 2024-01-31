defmodule MetaLogger do
  @moduledoc """
  A logger wrapper to keep logger metadata of caller processes.
  """

  require Logger

  @metadata ~w(dictionary $logger_metadata$)a

  @type chardata_or_fun :: IO.chardata() | String.Chars.t() | (any() -> any())
  @type metadata :: keyword()
  @type payload :: struct() | list() | chardata_or_fun()

  Enum.each(~w(debug error info warning)a, fn level ->
    @doc """
    Logs a #{level} message keeping logger metadata from caller processes.
    Returns `:ok` or an `{:error, reason}` tuple.

    ## Examples

        iex> #{inspect(__MODULE__)}.#{level}("hello?")
        :ok

        iex> #{inspect(__MODULE__)}.#{level}(fn -> "dynamically calculated debug" end)
        :ok

        iex> #{inspect(__MODULE__)}.#{level}(fn ->
        ...>   {"dynamically calculated #{level}", [additional: :metadata]}
        ...> end)
        :ok

    """
    @spec unquote(level)(chardata_or_fun()) :: :ok
    @spec unquote(level)(chardata_or_fun(), metadata()) :: :ok
    def unquote(level)(chardata_or_fun, metadata \\ []) do
      set_logger_metadata_from_parent_processes()

      Logger.unquote(level)(chardata_or_fun, metadata)
    end
  end)

  @doc """
  Logs a warning message keeping logger metadata from caller processes.
  Returns `:ok` or an `{:error, reason}` tuple.

  ## Examples

      iex> #{inspect(__MODULE__)}.warn("hello?")
      :ok

      iex> #{inspect(__MODULE__)}.warn(fn -> "dynamically calculated debug" end)
      :ok

      iex> #{inspect(__MODULE__)}.warn(fn ->
      ...>   {"dynamically calculated warning", [additional: :metadata]}
      ...> end)
      :ok

  """
  @deprecated "Use MetaLogger.warning/2 instead."
  @spec warn(chardata_or_fun()) :: :ok
  @spec warn(chardata_or_fun(), metadata()) :: :ok
  def warn(chardata_or_fun, metadata \\ []), do: warning(chardata_or_fun, metadata)

  @doc """
  Logs a message with given `level` keeping logger metadata from caller processes.

  Can accept a custom struct if it implements MetaLogger.Formatter protocol.

  Returns `:ok` or an `{:error, reason}` tuple.

  ## Examples

      iex> #{inspect(__MODULE__)}.log(:info, "mission accomplished")
      :ok

      iex> #{inspect(__MODULE__)}.log(:error, fn -> "dynamically calculated info" end)
      :ok

      iex> #{inspect(__MODULE__)}.log(:warning, fn ->
      ...>   {"dynamically calculated info", [additional: :metadata]}
      ...> end)
      :ok

  """
  @spec log(atom(), payload()) :: :ok
  @spec log(atom(), payload(), metadata()) :: :ok
  def log(level, payload, metadata \\ [])

  def log(level, data_struct, metadata) when is_struct(data_struct) do
    formatted_log = MetaLogger.Formatter.format(data_struct)

    log(level, formatted_log, metadata)
  end

  def log(level, logs, metadata) when is_atom(level) and is_list(logs),
    do: Enum.each(logs, &log(level, &1, metadata))

  def log(level, chardata_or_fun, metadata) when is_atom(level) do
    set_logger_metadata_from_parent_processes()

    Logger.log(level, chardata_or_fun, metadata)
  end

  @spec set_logger_metadata_from_parent_processes() :: :ok
  defp set_logger_metadata_from_parent_processes, do: Logger.metadata(metadata())

  @doc """
  Returns the logger metadata from the current process and caller processes.

  ## Examples

      iex> #{inspect(__MODULE__)}.metadata()
      []

      iex> #{inspect(__MODULE__)}.metadata()
      [metadata1: "value2", metadata2: "value2"]

  """
  @spec metadata() :: metadata()
  def metadata do
    :"$callers"
    |> Process.get()
    |> List.wrap()
    |> Enum.reduce(Logger.metadata(), &merge_logger_metadata_from_parent_process/2)
  end

  @spec merge_logger_metadata_from_parent_process(pid(), metadata()) :: metadata()
  defp merge_logger_metadata_from_parent_process(parent_pid, merged_metadata) do
    parent_pid
    |> get_process_logger_metadata()
    |> Keyword.merge(merged_metadata)
  end

  @spec get_process_logger_metadata(pid()) :: metadata()
  defp get_process_logger_metadata(pid) do
    pid
    |> Process.info()
    |> get_in(@metadata)
    |> case do
      process_metadata when is_map(process_metadata) -> Map.to_list(process_metadata)
      nil -> []
    end
  end
end
