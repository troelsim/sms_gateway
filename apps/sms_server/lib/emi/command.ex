defmodule EMI.Command do  
  require Logger
  def parse(30, token_list) do
    [adc, oadc, ac, nrq, nad, npid, dd, ddt, vp, amsg | _ ] = token_list
    {30, [
      adc: adc,  # Address code recipient (required)
      oadc: oadc, # Address code originator
      ac: Base.decode16(ac),   # Authentication code originator
      nrq: nrq,  # Notification requested
      nad: nad,  # Notification address
      npid: npid, # Notification pid value (4 num char)
      dd: dd,   # Deferred delivery request
      ddt: ddt,  # Deferred delivery time DDMMYYHHmm
      vp: vp,   # Validity period
      amsg: Base.decode16!(amsg, case: :mixed) # Alphanumeric message, max length 640.
    ]}
  end

  def parse(1, [adc, oadc, ac, mt, msg]) do
    {1, [
      adc: adc,
      oadc: oadc,
      ac: ac,
      mt: mt,
      msg: case mt do
        "2" -> msg
        "3" -> Base.decode16!(msg, case: :mixed)
      end
    ]}
  end
  
  def run({30, command}) do
    Logger.info "Send SMS to #{command[:adc]} with message #{command[:amsg]}"
  end

  def run({1, command}) do
    Logger.info "Send SMS to #{command[:adc]} with message #{command[:msg]}"
    {:ok, status_code} = Plivo.Client.send_sms("+45"<>command[:adc], command[:msg])
    Logger.info "Status code: #{status_code}"
    {1,
    [
      ack: "A",
      sm: "",
      adc: "#{command[:adc]}:#{timestamp}"
    ]}
  end

  def timestamp do
    {{year, month, day}, {hours, minutes, seconds}} = :calendar.local_time
    Enum.join(Enum.map([
      day,
      month,
      rem(year, 1000),
      hours,
      minutes,
      seconds
    ], fn s -> s|> Integer.to_string |> String.rjust(2, ?0) end))
  end


end
