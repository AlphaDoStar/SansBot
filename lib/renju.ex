defmodule Renju do
  @base_url "https://renju.saroro.dev"
  @content_type [{"Content-Type", "application/json"}]

  def create(user_id) do
    with {:ok, body} <- create_game(),
      {:ok, session_id} <- extract_session_id(body),
      {:ok, base64} <- fetch_image_base64(body),
      {:ok, _session_id} <- Renju.SessionManager.put(user_id, session_id) do
      {:ok, base64}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def move(user_id, pos) do
    case Renju.SessionManager.get(user_id) do
      nil ->
        {:error, "게임이 시작되지 않았습니다."}

      session_id ->
        url = @base_url <> "/api/renju/move"
        body = JSON.encode!(%{
          session_id: session_id,
          pos: pos
        })

        with {:ok, response_body} <- make_post_request(url, body),
          {:ok, base64} <- fetch_image_base64(response_body) do
          if String.ends_with?(response_body["result"], "_wins"), do: delete(user_id)
          {:ok, {response_body, base64}}
        else
          {:error, reason} -> {:error, reason}
        end
    end
  end

  def delete(user_id) do
    url = @base_url <> "/api/renju/remove_game"
    body = JSON.encode!(%{session_id: Renju.SessionManager.get(user_id)})
    make_post_request(url, body)
    Renju.SessionManager.delete(user_id)
  end

  defp create_game do
    url = @base_url <> "/api/renju/create_game"
    body = JSON.encode!(%{
      ai_setting: %{
        turn_time: 3000,
        handicap: 0,
        strength: 100
      }
    })

    make_post_request(url, body)
  end

  defp make_post_request(url, body) do
    case HTTPoison.post(url, body, @content_type, recv_timeout: 10_000) do
      {:ok, %HTTPoison.Response{status_code: 201, body: response_body}} ->
        JSON.decode(response_body)

      {:ok, %HTTPoison.Response{status_code: code, body: response_body}} ->
        {:error, "HTTP 요청 실패: 상태 코드 #{code}, 응답 본문: #{inspect(response_body, pretty: true)}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP 요청 오류: #{reason}"}
    end
  end

  defp extract_session_id(%{"session_id" => session_id}), do: {:ok, session_id}
  defp extract_session_id(_), do: {:error, "세션 ID 추출 실패"}

  defp fetch_image_base64(%{"image_url" => image_url}) do
    case get_image(@base_url <> image_url) do
      {:ok, body} -> {:ok, Base.encode64(body)}
      {:error, reason} -> {:error, reason}
    end
  end
  defp fetch_image_base64(_), do: {:error, "이미지 URL 추출 실패"}

  defp get_image(image_url) do
    case HTTPoison.get(image_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "이미지 다운로드 실패: #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP 요청 실패: #{reason}"}
    end
  end
end
