defmodule UpyunTest do

  use ExUnit.Case
  doctest Upyun

  @bucket "travis"
  @operator "travisci"
  @password "testtest"

  test "the truth" do
    assert 1 + 1 == 2
  end
end
