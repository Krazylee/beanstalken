defmodule BeanstalkenTest.YAML do
  use ExUnit.Case

  alias Beanstalken.YAML

  test "parse header" do
    sample_string = "---\n- test\n"
    { :ok, content } = YAML.parse_header(sample_string)
    assert content == "- test\n"
  end

  test "parse sequence" do
    sample_string = "- one\n- two\n"
    assert ["one", "two"] == YAML.parse_sequence(sample_string)
  end

  test "parse mapping" do
    sample_string = "one: 1\ntwo: 2\n"
    assert [one: "1", two: "2"] == YAML.parse_mapping(sample_string)
  end
end
