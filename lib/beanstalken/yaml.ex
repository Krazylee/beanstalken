defmodule Beanstalken.YAML do

  def parse(body) do
    case parse_header(body) do
      { :ok, content } ->
        case content do
          <<"-", _::bytes>> ->
            parse_sequence(content)
          _ ->
            parse_mapping(content)
        end
      _ ->
        body
    end
  end

  def parse_header(body) do
    case body do
      <<"---\n", content::binary>> ->
        { :ok, content }
      _ ->
        body
    end
  end

  def parse_sequence(content) do
    parse_sequence(content, [])
  end

  def parse_sequence(content, acc) when byte_size(content) == 0 do
    Enum.reverse acc
  end

  def parse_sequence(<<"- ", item::binary>>, acc) do
    [value | more_data] = seperate_items(item, "\n")
    parse_sequence(more_data, [value | acc])
  end

  def parse_sequence([<<"- ", head::binary>> | tail], acc) do
    parse_sequence(tail, [head | acc])
  end

  def parse_sequence([], acc) do
    parse_sequence("", acc)
  end

  def seperate_items(item, seperator) do
    String.split(item, seperator, parts: :infinity, trim: true)
  end

  def parse_mapping(content) do
    parse_mapping(content, [])
  end

  def parse_mapping(content, acc) when byte_size(content) == 0 do
    Enum.reverse acc
  end

  def parse_mapping(content, acc) when is_binary(content) do
    [pair | items] = seperate_items(content, "\n")

    [key, value] = seperate_items(pair, ": ")
    parse_mapping(items, [{String.to_atom(key), value} | acc])
  end

  def parse_mapping([], acc) do
    parse_mapping("", acc)
  end

  def parse_mapping(content, acc) when is_list(content) do
    [pair | items] = content

    [key, value] = seperate_items(pair, ": ")
    parse_mapping(items, [{String.to_atom(key), value} | acc])
  end
end
