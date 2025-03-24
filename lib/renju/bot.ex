defmodule Renju.Bot do
  use IrisEx.Bot

  on :message do
    match "!renju" do
      case Renju.create(chat.sender.id) do
        {:ok, base64} ->
          reply("""
          오목 게임이 시작되었습니다.
          !renju (pos)
          """ |> String.trim())
          reply_image(base64)

        {:error, reason} ->
          reply(reason)
      end
    end

    match "!renju clear" do
      Renju.delete(chat.sender.id)
      reply("#{chat.sender.name} 님의 세션이 삭제되었습니다.")
    end

    match ~r/^!renju ([A-Za-z]\d+)$/ do
      [pos] = args
      case Renju.move(chat.sender.id, pos) do
        {:ok, {body, base64}} ->
          handle_result(body) |> reply()
          reply_image(base64)

        {:error, reason} ->
          reply(reason)
      end
    end
  end

  defp handle_result(%{"result" => result, "result_msg" => message}) do
    case result do
      "b_wins" -> "흑돌(⚫) 승리!"
      "w_wins" -> "백돌(⚪) 승리!"
      "forbid" -> "금수입니다."
      "occupied" -> "이미 돌이 있는 위치입니다."
      "3" -> "33입니다."
      "4" -> "44입니다."
      "6" -> "장목(육목)입니다."
      "invalid" -> "올바르지 않은 위치입니다."
      _ -> message
    end
  end
end
