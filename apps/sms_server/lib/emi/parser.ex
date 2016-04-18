defmodule EMI.Parser do
  require Integer
  def tokenize(string) do
    string
     |> String.strip
     |> String.split("/")
  end

  def parse(string) do
    token_list = tokenize(string |> to_string)
    {:ok, header} = parse_header(Enum.slice(token_list, 0..3))
    EMI.Command.parse(header[:ot], Enum.slice(token_list, 4..-2))
  end

  def run(command) do
    {:ok, EMI.Command.run(command) |> build_response}
  end

  defp parse_header(token_list) do
    case Enum.map(token_list, &parse_or_gtfo(&1)) do
      [trn, len, o_r, ot] -> {:ok, [
        trn: trn,  # Transaction reference number
        len: len,  # Length of message (20 lsb)
        o_r: o_r,  # Operation/response
        ot: ot     # Operation type
      ]}
      _ -> :error
    end
  end

  defp build_response({operation, command}) do
    body = command |> Enum.map(fn {k, v} -> v end) |> Enum.join("/")
    allbutchecksum = ['01', message_length(body), 'R', zeropad(operation, 2)] ++ [body, ""] |> Enum.join("/")
    allbutchecksum <> Base.encode16(<<checksum(allbutchecksum)>>)
  end

  defp message_length(body) do
    # A header is always 2+5+1+2 characters, excluding slashes. Checksum is 3 characters. With slashes, this means
    String.length(body) + 17 |> zeropad(5)
  end

  defp checksum(str) do
    [head | message] = str |> to_char_list
    if message == [] do
      head
    else
      head + checksum(message) |> rem(256)
    end
  end

  defp zeropad(int, size \\ 2) do
    int |> Integer.to_string |> String.rjust(size, ?0)
  end

  defp parse_or_gtfo(string) do
    case Integer.parse(string) do
      {number, _} -> number
      :error -> string
    end
  end
end
