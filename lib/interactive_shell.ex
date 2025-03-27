defmodule InteractiveShell do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def evaluate(code) do
    GenServer.call(__MODULE__, {:eval, code}, 60_000)
  end

  def get_context do
    GenServer.call(__MODULE__, :get_context)
  end

  def reset do
    GenServer.cast(__MODULE__, :reset)
  end

  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_call({:eval, code}, _from, bindings) do
    try do
      {result, new_bindings} = Code.eval_string(code, bindings)
      {:reply, {:ok, inspect(result, pretty: true)}, new_bindings}
    rescue
      error ->
        {:reply, {:error, inspect(error, pretty: true)}, bindings}
    end
  end

  @impl true
  def handle_call(:get_context, _from, bindings) do
    {:reply, bindings, bindings}
  end

  @impl true
  def handle_cast(:reset, _bindings) do
    {:noreply, []}
  end
end
