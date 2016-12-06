defmodule UpyunTest do

  use ExUnit.Case
  doctest Upyun

  @bucket   "travis"
  @operator "travisci"
  @password "testtest"

  # @bucket   "hlj-img"
  # @operator System.get_env("UPYUN_OPERATOR")
  # @password System.get_env("UPYUN_PASSWORD")

  @prefix   "/upload/test/elixir-upyun"

  setup do
    policy = %Upyun{ bucket: @bucket, operator: @operator, password: @password }

    on_exit fn ->
      Upyun.delete(policy, "#{@prefix}/README.md")
      Upyun.delete(policy, "#{@prefix}/README2.md")
      Upyun.delete(policy, "#{@prefix}/test/readme/README.md")
      Upyun.delete(policy, "#{@prefix}/test/upyun_test.exs")
      Upyun.delete(policy, "#{@prefix}/test/test_helper.exs")
    end

    {:ok, %{policy: policy}}
  end


  test "list objects", %{policy: policy} do
    {:ok, list} = Upyun.list(policy)
    assert is_list(list)
  end


  test ".upload", %{policy: policy} do
    assert Upyun.upload(policy, "README.md", "#{@prefix}/README.md") == :ok
  end


  test ".upload with custom keyword list headers", %{policy: policy} do
    assert Upyun.upload(policy, "README.md", "#{@prefix}/README.md", headers: %{
      "Content-Type" => "text/plain"
    }) == :ok
  end


  test ".put", %{policy: policy} do
    assert Upyun.put(policy, "Hello", "#{@prefix}/README.md") == :ok
  end


  test ".put with custom headers", %{policy: policy} do
    assert Upyun.put(policy, "hello", "#{@prefix}/README2.md", headers: %{
      "Content-Type" => "text/plain"
    }) == :ok
  end


  test ".put with non-existing path", %{policy: policy} do
    assert Upyun.put(policy, "hello", "#{@prefix}/test/readme/README.md") == :ok
    {:file, 5, _} = Upyun.info(policy, "#{@prefix}/test/readme/README.md")
  end


  test ".info", %{policy: policy} do
    assert Upyun.put(policy, "hello", "#{@prefix}/README.md") == :ok
    {:file, 5, _} = Upyun.info(policy, "#{@prefix}/README.md")
    {:dir, 0, _}  = Upyun.info(policy, "#{@prefix}/empty_dir")
  end


  test ".delete", %{policy: _policy} do
    # already tested deleting in setup
  end


  test ".upload_dir", %{policy: policy} do
    Upyun.upload_dir(policy, "./test", "#{@prefix}/elixir-test/test")
  end


end
