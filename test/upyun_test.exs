defmodule UpyunTest do

  use ExUnit.Case
  doctest Upyun

  @bucket   "travis"
  @operator "travisci"
  @password "testtest"

  @prefix   "/upload/test/elixir-upyun"

  setup do
    policy = %Upyun{ bucket: @bucket, operator: @operator, password: @password }

    # avoid "too many requests of the same uri"
    n = :rand.uniform(10000)
    path = @prefix <> "/README-#{n}.md"

    on_exit fn ->
      Upyun.delete(policy, path)
    end

    {:ok, %{policy: policy, path: path}}
  end


  test "list objects", %{policy: policy} do
    {:ok, list} = Upyun.list(policy)
    assert is_list(list)
  end


  test ".upload", %{policy: policy, path: path} do
    assert Upyun.upload(policy, "README.md", path) == :ok
  end


  test ".upload with custom keyword list headers", %{policy: policy, path: path} do
    assert Upyun.upload(policy, "README.md", path, headers: %{
      "Content-Type" => "text/plain"
    }) == :ok
  end


  test ".put", %{policy: policy, path: path} do
    assert Upyun.put(policy, "Hello", path) == :ok
  end


  test ".put with custom headers", %{policy: policy, path: path} do
    assert Upyun.put(policy, "hello", path, headers: %{
      "Content-Type" => "text/plain"
    }) == :ok
  end


  test ".put with non-existing path", %{policy: policy, path: path} do
    assert Upyun.put(policy, "hello", path) == :ok
    {:file, 5, _} = Upyun.info(policy, path)
  end


  # This test needs to be reviewed.
  @tag need_inspect: true
  test ".info", %{policy: policy, path: path} do
    assert Upyun.put(policy, "hello", path) == :ok
    {:file, 5, _} = Upyun.info(policy, path)
    {:dir, 0, _}  = Upyun.info(policy, "/")
    {:error, :not_found}  = Upyun.info(policy, "#{@prefix}/empty_dir")
  end


  test ".delete", %{policy: _policy} do
    # already tested deleting in setup
  end


  test ".upload_dir", %{policy: policy} do
    Upyun.upload_dir(policy, "./test", "#{@prefix}/elixir-test/test")
  end


end
