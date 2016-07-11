defmodule UpyunTest do

  use ExUnit.Case
  doctest Upyun

  @bucket   "travis"
  @operator "travisci"
  @password "testtest"

  test "list objects" do
    {:ok, list} = Upyun.list(policy)
    assert is_list(list)
  end

  test ".upload" do
    assert Upyun.upload(policy, "README.md", "/README.md") == :ok
  end

  test ".upload with custom keyword list headers" do
    assert Upyun.upload(policy, "README.md", "/README.md", headers: %{
      "Content-Type" => "text/plain"
    }) == :ok
  end

  test ".upload with custom map headers" do
    assert Upyun.upload(policy, "README.md", "/README.md", %{ headers: %{
      "Content-Type" => "text/plain"
    }}) == :ok
  end

  test ".put" do
    assert Upyun.put(policy, "Hello", "/README.md") == :ok
  end

  test ".put with custom headers" do
    assert Upyun.put(policy, "hello", "/README2.md", headers: %{
      "Content-Type" => "text/plain"
    }) == :ok
  end

  test ".put with non-existing path" do
    assert Upyun.put(policy, "hello", "/test/readme/README.md") == :ok
    {:file, 5, _} = Upyun.info(policy, "/test/readme/README.md")
  end

  test ".info" do
    assert Upyun.put(policy, "hello", "/README.md") == :ok
    {:file, 5, _} = Upyun.info(policy, "/README.md")
    {:dir, 0, _}  = Upyun.info(policy, "/empty_dir")
  end

  test ".delete" do
    Upyun.delete(policy, "/README.md")
    Upyun.delete(policy, "/README2.md")
    Upyun.delete(policy, "/test/readme/README.md")
    Upyun.delete(policy, "/elixir-test/test/upyun_test.exs")
    Upyun.delete(policy, "/elixir-test/test/test_helper.exs")
  end

  defp policy do
    %Upyun{ bucket: @bucket, operator: @operator, password: @password }
  end

  test ".upload_dir" do
    Upyun.upload_dir(policy, "./test", "/elixir-test/test")
  end
end
