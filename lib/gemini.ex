defmodule Gemini do
  @base_url "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro-exp-03-25:generateContent?key="

  def question(text) do
    api_key = System.get_env("GEMINI_API_KEY", "")
    payload = JSON.encode!(%{contents: [%{parts: [%{text: text}]}]})
    header = [{"Content-Type", "application/json"}]

    case HTTPoison.post(@base_url <> api_key, payload, header, recv_timeout: 60_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        JSON.decode!(body)
        |> get_in(["candidates", Access.at(0), "content", "parts", Access.at(0), "text"])

      {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
        "[#{code}] 오류가 발생했습니다: #{inspect(body, pretty: true)}"

      {:error, %HTTPoison.Error{reason: reason}} ->
        "오류가 발생했습니다: #{inspect(reason, pretty: true)}"
    end
  end

  def send(room_id, text) do
    answer = question(text)
    IrisEx.Client.send_text(room_id, answer)
  end
end
