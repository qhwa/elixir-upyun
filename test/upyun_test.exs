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

  test ".put" do
    assert Upyun.put(policy, "README.md", "/README.md") == :ok
  end

  test ".put_body" do
    assert Upyun.put_body(policy, "Hello", "/README.md") == :ok
  end

  test ".put with custom headers" do
    assert Upyun.put_body(policy, "hello", "/README2.md", headers: %{
      "Content-Type" => "text/plain"
    }) == :ok
  end

  test ".put with non-existing path" do
    assert Upyun.put_body(policy, "hello", "/test/readme/README.md") == :ok
    {:file, 5, _} = Upyun.info(policy, "/test/readme/README.md")
  end

  test ".info" do
    assert Upyun.put_body(policy, "hello", "/README.md") == :ok
    {:file, 5, _} = Upyun.info(policy, "/README.md")
    {:dir, 0, _}  = Upyun.info(policy, "/empty_dir")
  end

  test ".delete" do
    Upyun.delete(policy, "/README.md")
    Upyun.delete(policy, "/README2.md")
    Upyun.delete(policy, "/test/readme/README.md")
  end

  defp policy do
    %Upyun{ bucket: @bucket, operator: @operator, password: @password }
  end
end
