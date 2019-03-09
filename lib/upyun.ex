defmodule Upyun do

  @moduledoc """
  This is a simple client library for Upyun.

  ## Notes on configuration
  
  All the APIs need a `policy` to be passed in. A `policy` contains
  the configuration information about the connection detail, such
  as bucket, operator, and api endpoint.

  A typical policy can be:

  ```elixir
  %Upyun{bucket: "my-bucket", operator: "bob", password: "secret-password", endpoint: :v0}
  ```

  ## Examples:

  ### upload

  ```
  policy = %Upyun{bucket: "my-bucket", operator: "bob", password: "secret-password", endpoint: :v0}
  policy |> Upyun.upload("README.md", "/test/README.md")
  #=> :ok
  ```
  """
  @type policy :: %Upyun{bucket: String.t, operator: String.t, password: String.t, endpoint: atom}
  defstruct bucket: nil, operator: nil, password: nil, endpoint: :v0

  @type info :: {:file, integer, integer} | {:dir, integer, integer}

  # APIs

  @doc """
  List entries in a path.

  * `policy` - upyun configuration object
  * `path` - remote directory to list

  Returns a list of objects.

  ## Examples

  ```elixir
  policy |> Upyun.list("/")
  #=> a list of items, e.g. {:file, "file"} / {:dir, "folder"}
  ```
  """
  @spec list(policy, binary) :: :ok | {:error, any}
  def list(policy, path \\ "/") do
    resp = policy
      |> to_url(path)
      |> HTTPoison.get!(headers(policy))

    case resp.status_code do
      200 ->
        {:ok, parse_list(resp.body)}
      _ ->
        {:error, resp.body}
    end

  end


  defp to_url(policy, path) do
    %{bucket: bucket, endpoint: endpoint} = policy
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

  * `policy` - upyun configuration object
  * `path` - remote object path

  ## Examples

  ```elixir
  # for file:
  policy |> Upyun.info("hehe.txt")
  #=> {:file, 150, 1448958896}

  # for folder:
  policy |> Upyun.info("empty_dir")
  #=> {:dir, 0, 1448958896}`
  ```
  """
  @spec info(policy, binary) :: info | {:error, :not_found} | {:error, any}
  def info(policy, path) do
    resp = policy
      |> to_url(path)
      |> HTTPoison.head!(headers(policy))

    case resp.status_code do
      200 -> parse_info(resp)
      404 -> {:error, :not_found}
      _   -> {:error, resp.body}
    end
  end


  defp parse_info(resp) do
    headers = resp.headers
      |> Enum.into(%{}, fn({k, v}) -> {
        k |> String.downcase |> String.to_atom,
        v
      } end)

    {
      parse_upyun_file_type(headers),
      parse_upyun_file_size(headers),
      parse_upyun_file_date(headers)
    }
  end


  defp parse_upyun_file_type(%{:"x-upyun-file-type" => "file"}) do
    :file
  end


  defp parse_upyun_file_type(%{:"x-upyun-file-type" => "folder"}) do
    :dir
  end


  defp parse_upyun_file_type(_) do
    :unknown
  end


  defp parse_upyun_file_size(%{:"x-upyun-file-size" => num}) when is_binary(num) do
    String.to_integer(num)
  end


  defp parse_upyun_file_size(_) do
    0
  end


  defp parse_upyun_file_date(%{:"x-upyun-file-date" => date}) do
    String.to_integer(date)
  end


  defp parse_upyun_file_date(_) do
    nil
  end


  @doc """
  Upload a file from local to remote.

  * `policy` - upyun configuration object
  * `local_path` - path of the local file to upload
  * `remote_path` - remote object path to store the file
  * `opts` - (optional) options for making the HTTP request by `HTTPoison`

  Returns `:ok` if successful.

  ## Examples

  ```elixir
  policy = %Upyun{bucket: "my-bucket", operator: "bob", password: "secret-password", endpoint: :v0}
  policy |> Upyun.upload("/path/to/local/file", "/path/to/remote/object")
  #=> :ok
  ```
  
  ### Sending custom headers

  By default, `elixir-upyun` will automatically send `Content-Type` header for you.
  You can send custom headers via options. Like:

  ```elixir
  policy |> Upyun.upload("/local/path", "/remote/path", headers: [
    {:"Content-Type", "text/plain"},
    {:"X-Foo", "BAR"}
  ])
  ```
  """
  @spec upload(policy, binary, binary, [any]) :: :ok | {:error, any}
  def upload(policy, local_path, remote_path, opts \\ []) do
    opts = opts
      |> Keyword.put_new(
        :headers,
        [{:"Content-Type", MIME.from_path(local_path)}]
      )
    put(
      policy,
      File.read!(local_path),
      remote_path,
      opts
    )
  end


  @doc """
  Create or update remote file with raw content.

  * `policy` - upyun configuration object
  * `content` - content of the file
  * `path` - remote object path to store the file
  * `opts` - (optional) options for making the HTTP request by `HTTPoison`

  Returns `:ok` if successful.

  ## Examples

  ```elixir
  content = \"""
    <html>
      <head>
        <title>Hello, world</title>
      </head>
      <body>Nice to see you.</body>
    </html>
  \"""
  policy |> Upyun.put(content, "/remote/path")
  #=> :ok
  ```
  """
  @default_upload_timeout 120_000
  @spec put(policy, binary, binary, [any]) :: :ok
  def put(policy, content, path, opts \\ []) do
    hds = headers(policy, opts)
    timeout = Keyword.get(opts, :timeout, @default_upload_timeout)

    res = policy |> to_url(path) |> HTTPoison.put!(content, hds, recv_timeout: timeout)
    case res do
      %{status_code: 200} -> :ok
      %{status_code: 429, request_url: url} -> {:already_exists, url}
      %{body: body} -> {:error, body}
    end
  end


  @doc """
  Upload all files recursively in local directory to remote.
  Thery are uploaded one by one currently.
  TODO: upload parallelly

  * `policy` - upyun configuration object
  * `local_dir` - local directory to upload
  * `remote_path` - remote object path to store the files
  * `opts` - (optional) options for making the HTTP request by `HTTPoison`

  Returns an list of result object. A result object is a tuple,
  with local file name first, and the result (`:ok`) followed.
  
  ## Examples
  
  ```elixir
  policy |> upload_dir("/etc", "/remote/etc")
  #=> [{"passwd", :ok}, {"fastab", :ok}, ...]
  ```
  """
  @spec upload_dir(policy, binary, binary, [any]) :: [{binary, :ok}]
  def upload_dir(policy, local_dir, remote_path, opts \\ []) do
    local_dir
    |> Path.join("**")
    |> Path.wildcard
    |> Enum.reject(&File.dir?/1)
    |> Enum.each(
      fn (file) ->
        local = file
          |> Path.expand
          |> Path.relative_to(Path.expand(local_dir))
        {file, upload(policy, file, Path.join(remote_path, local), opts)}
      end
    )
  end


  @doc """
  Delete a remote file.

  * `policy` - upyun configuration object
  * `path` - remote object path

  Returns `:ok` if remote file is successfully deleted or does not exist.

  ## Examples

  ```elixir
  policy |> Upyun.delete("/my/file")
  #=> :ok
  ```
  """
  @spec delete(policy, binary) :: :ok | {:error, any}
  def delete(policy, path) do
    resp = policy
      |> to_url(path)
      |> HTTPoison.delete!(headers(policy))

    case resp.status_code do
      200 -> :ok
      404 -> :ok
      _ -> {:error, resp.body}
    end
  end


  @doc """
  Get the content of remote file.

  * `policy` - upyun configuration object
  * `path` - remote object path

  Return the raw content string of the file.

  ## Examples

  ```elixir
  policy |> Upyun.get("/remote/file")
  #=> "content of the file..."
  ```
  """
  @spec get(policy, binary) :: binary | {:error, :file_not_found}
  def get(policy, path) do
    policy
      |> to_url(path)
      |> HTTPoison.get!(headers(policy))
      |> get_raw_content
  end

  ## helpers

  defp headers(policy) do
    headers(policy, [])
  end

  defp headers(policy, opts = [headers: hds]) when is_map(hds) do
    opts = opts |> Keyword.put(:headers, Map.to_list(hds))
    headers(policy, opts)
  end

  defp headers(policy, opts) when is_map(opts) do
    headers(policy, Map.to_list(opts))
  end

  defp headers(policy, opts) do
    %{operator: op, password: pw} = policy
    defaults = [
      {:"Accpet"        , "application/json"},
      {:"Authorization" , "Basic #{sign(op, pw)}"},
      {:"Date"          , time()}
    ]

    hds = Enum.map(opts[:headers] || [], fn {k, v} -> {:"#{k}", v} end)

    Keyword.merge(
      defaults,
      hds
    )
  end

  defp sign(op, pw) do
    Base.encode64(op <> ":" <> pw)
  end

  defp time do
    {date, {h, m, s}} = :calendar.universal_time
    {year, month, d}  = date

    month_name = ~w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
                  |> Enum.at(month - 1)
    day_name   = ~w[Mon Tue Wed Thu Fri Sat Sun]
                  |> Enum.at(:calendar.day_of_the_week(date) - 1)

    "#{day_name}, #{d} #{month_name} #{year} #{pad h}:#{pad m}:#{pad s} GMT"
  end


  defp pad(n) do
    n |> Integer.to_string |> String.pad_leading(2, "0")
  end


  defp get_raw_content(%HTTPoison.Response{status_code: 200, body: body}) do
    body
  end

  
  defp get_raw_content(%HTTPoison.Response{status_code: 404}) do
    {:error, :file_not_found}
  end


  defp get_raw_content(%{body: body}) do
    {:error, body}
  end

end

