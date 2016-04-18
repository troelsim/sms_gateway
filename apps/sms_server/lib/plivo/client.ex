defmodule Plivo.Client do
  require Logger
  use HTTPoison.Base

  @auth_id "***REMOVED***"
  @auth_token "***REMOVED***"
  @source_number "***REMOVED***"
  
  defp process_url(url) do
    "https://#{@auth_id}:#{@auth_token}@api.plivo.com/v1/Account/#{@auth_id}" <> url
  end

  defp process_request_headers(headers) do
    Enum.into(headers, [
      AUTH_ID: @auth_id,
      AUTH_TOKEN: @auth_token,
      "Content-Type": "application/json"
    ])
  end

  defp process_request_body(body) do
    Poison.encode!(body)
  end

  def send_sms(number, message) do
    {:ok, response} = Plivo.Client.post("/Message/", %Plivo.SMS{
      src: "ZafeGuard",
      dst: number,
      text: message
    })
    {:ok, response.status_code}
  end
end
