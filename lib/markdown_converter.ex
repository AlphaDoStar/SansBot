# Code by 헤히
defmodule MarkdownConverter do
  @moduledoc """
  마크다운 텍스트를 일반 텍스트로 변환하는 모듈입니다.
  """

  @token_start "⟦𪚥"
  @token_end "𪚥⟧"

  # 정규식 패턴들
  @patterns %{
    code_block: ~r/```(.*?)\n([\s\S]*?)```/s,
    inline_code: ~r/`([^`]+)`/,
    bold_italic: ~r/(\*\*\*|___)(.*?)\1/,
    bold: ~r/(\*\*|__)(.*?)\1/,
    italic: ~r/(\*|_)(.*?)\1/,
    strikethrough: ~r/~~(.*?)~~/,
    image: ~r/!\[([^\]]*)\]\(([^)]+)\)/,
    horizontal_line: ~r/^([-*]){3,}$/m,
    heading: ~r/^(#+)\s+(.*)/m,
    list: ~r/^(\s*)([-*])\s+(.*)/m,
    blockquote: ~r/^(>+)\s+(.*)/m
  }

  @doc """
  마크다운 텍스트를 일반 텍스트로 변환합니다.

  ## 예시

      iex> MarkdownConverter.md_to_text("이건 **매우 중요한** `code`입니다.")
      "이건 「매우 중요한」[code]입니다."

  """
  def md_to_text(markdown) do
    # 저장할 코드 블록과 인라인 코드
    code_blocks = []
    inline_codes = []

    # 단계 1: 코드 블록과 인라인 코드 추출 및 토큰화
    {result, code_blocks, inline_codes} =
      markdown
      |> extract_code_blocks(code_blocks)
      |> extract_inline_codes(inline_codes)

    # 단계 2: 마크다운 변환
    result =
      result
      |> replace_pattern(@patterns.bold_italic, "【\\2】")
      |> replace_pattern(@patterns.bold, "「\\2」")
      |> replace_pattern(@patterns.italic, "\"\\2\"")
      |> replace_strikethrough()
      |> replace_pattern(@patterns.image, "[\\2]")
      |> replace_horizontal_line()
      |> replace_headings()
      |> replace_lists()
      |> replace_blockquotes()

    # 단계 3: 토큰 복원
    result =
      restore_inline_codes(result, inline_codes)
      |> restore_code_blocks(code_blocks)

    result
  end

  # 코드 블록 추출 및 토큰화
  defp extract_code_blocks(text, code_blocks) do
    {processed_text, updated_blocks} =
      Regex.scan(@patterns.code_block, text, return: :index)
      |> Enum.reduce({text, code_blocks}, fn [{full_match_start, full_match_len}, {lang_start, lang_len}, {code_start, code_len}], {acc_text, acc_blocks} ->
        full_match = binary_part(text, full_match_start, full_match_len)
        lang = binary_part(text, lang_start, lang_len) |> String.trim()
        code = binary_part(text, code_start, code_len) |> String.trim()

        lang = if lang == "", do: "Code", else: lang
        token = "#{@token_start}CB#{length(acc_blocks)}#{@token_end}"

        updated_text = String.replace(acc_text, full_match, token, global: false)
        updated_blocks = acc_blocks ++ [{lang, code}]

        {updated_text, updated_blocks}
      end)

    {processed_text, updated_blocks, []}
  end

  # 인라인 코드 추출 및 토큰화
  defp extract_inline_codes({text, code_blocks, _}, inline_codes) do
    {processed_text, updated_codes} =
      Regex.scan(@patterns.inline_code, text, return: :index)
      |> Enum.reduce({text, inline_codes}, fn [{full_match_start, full_match_len}, {code_start, code_len}], {acc_text, acc_codes} ->
        full_match = binary_part(text, full_match_start, full_match_len)
        code = binary_part(text, code_start, code_len)

        token = "#{@token_start}IC#{length(acc_codes)}#{@token_end}"

        updated_text = String.replace(acc_text, full_match, token, global: false)
        updated_codes = acc_codes ++ [code]

        {updated_text, updated_codes}
      end)

    {processed_text, code_blocks, updated_codes}
  end

  # 일반 패턴 교체
  defp replace_pattern(text, pattern, replacement) do
    Regex.replace(pattern, text, replacement)
  end

  # 취소선 처리
  defp replace_strikethrough(text) do
    Regex.replace(@patterns.strikethrough, text, fn _, content ->
      content
      |> String.graphemes()
      |> Enum.map(&(&1 <> "\u0336"))
      |> Enum.join("")
    end)
  end

  # 수평선 처리
  defp replace_horizontal_line(text) do
    Regex.replace(@patterns.horizontal_line, text, String.duplicate("━", 20))
  end

  # 헤딩 처리
  defp replace_headings(text) do
    Regex.replace(@patterns.heading, text, fn _, hashes, content ->
      level = String.length(hashes)
      indent = String.duplicate(" ", max(0, 8 - level * 2))
      "\n#{indent}『#{content}』\n"
    end)
  end

  # 리스트 처리
  defp replace_lists(text) do
    Regex.replace(@patterns.list, text, fn _, spaces, _, content ->
      level = div(String.length(spaces), 2)
      markers = ["⦁", "￮", "▸", "▹"]
      marker = Enum.at(markers, min(level, length(markers) - 1))
      "#{String.duplicate(" ", level * 2)}#{marker} #{content}"
    end)
  end

  # 인용구 처리
  defp replace_blockquotes(text) do
    Regex.replace(@patterns.blockquote, text, fn _, quotes, content ->
      level = String.length(quotes)
      "#{String.duplicate(" ", level * 2)}#{String.duplicate("| ", level)}#{content}"
    end)
  end

  # 인라인 코드 토큰 복원
  defp restore_inline_codes(text, inline_codes) do
    Enum.reduce(Enum.with_index(inline_codes), text, fn {code, index}, acc ->
      token = "#{@token_start}IC#{index}#{@token_end}"
      String.replace(acc, token, "[#{code}]")
    end)
  end

  # 코드 블록 토큰 복원
  defp restore_code_blocks(text, code_blocks) do
    Enum.reduce(Enum.with_index(code_blocks), text, fn {{lang, code}, index}, acc ->
      token = "#{@token_start}CB#{index}#{@token_end}"
      border = String.duplicate("━", 5)
      formatted_block = "\n┏#{border} #{lang} #{border}┓\n#{code}\n┗#{String.duplicate("━", 10 + div(String.length(lang) + 1, 2))}┛\n"
      String.replace(acc, token, formatted_block)
    end)
  end
end
