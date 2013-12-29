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

  def parse_sequence(content, acc) when size(content) == 0 do
    Enum.reverse acc
  end

  def parse_sequence(<<"- ", item::binary>>, acc) do
    [ value, more_data ] = seperate_items(item, "\n")
    parse_sequence(more_data, [value|acc])
  end

  def seperate_items(item, seperator) do
    String.split(item, seperator, global: false)
  end

  def parse_mapping(content) do
    parse_mapping(content, [])
  end

  def parse_mapping(content, acc) when size(content) == 0 do
    Enum.reverse acc
  end

  def parse_mapping(content, acc) do
    [key, data] = seperate_items(content, ": ")
    [value, more_data] = seperate_items(data, "\n")
    parse_mapping(more_data, [{binary_to_atom(key), value}|acc])
  end
end
