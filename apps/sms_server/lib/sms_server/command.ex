defmodule SMSServer.Command do
  def parse(line) do
    match = Regex.run(~r/^([A-Z]+)\s+(\+?\d+)\s+(.*)$/, String.strip(line))
    case match do
      [_, "SEND", phone_number, message] -> {:ok, {:send, phone_number, message}}
      _ -> {:error, :unknown_command}
    end
  end

  def run({:send, phone_number, message}) do
    {:ok, status} = Plivo.Client.send_sms(phone_number, message)
    {:ok, "#{status}\r\n"}
  end
end
