defmodule Renju.SessionManager do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(user_id) do
    Agent.get(__MODULE__, &Map.get(&1, user_id))
  end

  def put(user_id, session_id) do
    if get(user_id) do
      {:error, "이미 게임이 시작되었습니다."}
    else
      Agent.update(__MODULE__, &Map.put(&1, user_id, session_id))
      {:ok, session_id}
    end
  end

  def delete(user_id) do
    Agent.update(__MODULE__, &Map.delete(&1, user_id))
  end
end
