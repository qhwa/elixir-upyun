defmodule Upyun do

  @moduledoc """
  This is a simple client library for Upyun.
  """

  defstruct bucket: nil, operator: nil, password: nil, endpoint: :v0


  @doc """
  list folder entries.

  Returns a list of objects.

  ## Examples

    Upyun.list(policy, "/") #=> a list of items, e.g. {:file, "file"} / {:dir, "folder"}

  """
  def list(policy, path \\ "/") do
    resp = policy
      |> to_url(path)
      |> HTTPoison.get!(headers(policy))

    case resp.status_code do
      200 ->
        { :ok, parse_list(resp.body) }
      _ ->
        { :error }
    end

  end


  defp to_url(policy, path) do
    %{ bucket: bucket, endpoint: endpoint } = policy
    "https://#{endpoint}.api.upyun.com/#{bucket}#{path}"
  end


  defp parse_list(body) do
    body
      |> String.split("\n")
      |> Enum.map(&parse_line/1)
  end


  defp parse_line(line) do
    case String.split(line, "\t") do
      # TODO: add modified time data
      [name, "F" | _] -> {:dir, name}
      [name, "N" | _] -> {:file, name}
      _ -> nil
    end
  end


  @doc """
  Get information of an object.

  ### Examples

  for file: `Upyun.info(policy, "hehe.txt")  #=> { :file, 0, 1448958896 }`
  for folder: `Upyun.info(policy, "empty_dir")  #=> { :dir, 0, 1448958896 }`

  """
  def info(policy, path) do
    resp = policy
      |> to_url(path)
      |> HTTPoison.head!(headers(policy))

    case resp.status_code do
      200 -> parse_info(resp)
      404 -> { :error, :not_found }
      _   -> { :error, resp.body }
    end
  end


  defp parse_info(resp) do
    headers = resp.headers
      |> Enum.map(fn({k, v}) -> { String.to_atom(k), v } end)

    type = case headers[:"x-upyun-file-type"] do
      "file"   -> :file
      "folder" -> :dir
      _        -> :unkown
    end

    size = case headers[:"x-upyun-file-size"] do
      num when is_binary(num) -> String.to_integer(num)
      _ -> 0
    end

    date = String.to_integer(headers[:"x-upyun-file-date"])

    { type, size, date }
  end


  @doc """
  Upload a file from local to remote.

  Returns `:ok` if successful.
  """
  def upload(policy, local_path, remote_path, opts \\ %{}) do
    opts = case Map.get(opts, :headers) do
      true -> opts
      _ ->
        Map.put(opts, :headers, %{
          "Content-Type" => MIME.from_path(local_path)
        })
    end
    put(policy, File.read!(local_path), remote_path, opts)
  end


  @doc """
  Create or update remote file with raw content.

  Returns `:ok` if successful.
  """
  @default_upload_timeout 120000
  def put(policy, content, path, opts \\ %{}) do
    hds     = headers(policy) |> Map.merge(opts[:headers] || %{})
    timeout = Dict.get(opts, :timeout, @default_upload_timeout)

    %{ status_code: 200 } = policy
      |> to_url(path)
      |> HTTPoison.put!(content, hds, recv_timeout: timeout)

    :ok
  end


  @doc """
  Upload all files recursively in local directory to remote.
  Thery are uploaded one by one currently.
  TODO: upload parallelly
  """
  def upload_dir(policy, local_dir, remote_path, opts \\ %{}) do
    local_dir
    |> Path.join("**")
    |> Path.wildcard
    |> Enum.each(
      fn (file) ->
        local = Path.relative_to(Path.expand(file), Path.expand(local_dir))
        upload(policy, file, Path.join(remote_path, local), opts)
      end
    )
  end


  @doc """
  Delete a remote file.

  Returns `:ok` if remote file is successfully deleted or does not exist.
  """
  def delete(policy, path) do
    resp = policy
      |> to_url(path)
      |> HTTPoison.delete!(headers(policy))

    case resp.status_code do
      200 -> :ok
      404 -> :ok
      _ -> { :error, resp.body }
    end
  end

  ## helpers

  defp headers(policy) do
    %{ operator: op, password: pw } = policy
    %{
      "Accpet"        => "application/json",
      "Authorization" => "Basic #{sign(op, pw)}",
      "Date"          => time()
    }
  end

  defp sign(op, pw) do
    Base.encode64(op <> ":" <> pw)
  end

  defp time do
    {date, {h, m, s}}  = :calendar.universal_time
    { year, month, d } = date

    month_name = ~w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
                  |> Enum.at(month - 1)
    day_name   = ~w[Mon Tue Wed Thu Fri Sat Sun]
                  |> Enum.at(:calendar.day_of_the_week(date) - 1)

    h = h |> Integer.to_string |> String.rjust(2, ?0)
    m = m |> Integer.to_string |> String.rjust(2, ?0)
    s = s |> Integer.to_string |> String.rjust(2, ?0)
    d = d |> Integer.to_string |> String.rjust(2, ?0)

    "#{day_name}, #{d} #{month_name} #{year} #{h}:#{m}:#{s} GMT"
  end

end
