defmodule SansBot do
  use IrisEx.Bot

  on :message do
    match "와" do
      reply("샌즈")
    end

    match "와 샌즈" do
      reply("언더테일 아시는구나!")
    end

    match "진.짜" do
      reply("겁.나.어.렵.습.니.다")
    end

    match ~r/^!send (.+)$/ do
      [image_url] = args

      result = case HTTPoison.get(image_url) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          {:ok, Base.encode64(body)}

        {:ok, %HTTPoison.Response{status_code: status_code}} ->
          {:error, "이미지 다운로드 실패: #{status_code}"}

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, "HTTP 요청 실패: #{reason}"}
      end

      case result do
        {:ok, base64} -> reply_image(base64)
        {:error, reason} -> reply(reason)
      end
    end

    if chat.sender.name === "AlphaDo" do
      match ~r/^!eval\s+(.+)/ do
        [code] = args

        result = case SansBot.InteractiveShell.evaluate(code) do
          {:ok, result} -> result
          {:error, reason} -> reason
        end

        reply(result)
      end

      match "!reset" do
        SansBot.InteractiveShell.reset()
        |> reply()
      end
    end
  end

  on :new_member do
    reply("#{chat.sender.name} 님, 어서오세요!")
  end
end
