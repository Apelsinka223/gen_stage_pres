defmodule Demand.Manual do
  defmodule Producer do
    use GenStage

    def start_link(_) do
      GenStage.start_link(__MODULE__, %{}, [name: __MODULE__])
    end

    def init(_) do
      {:producer, %{iterator: 0}}
    end

    def handle_demand(demand, state) do
      IO.puts("demanded: #{demand}")

      Process.sleep(1_000)

      events = Enum.into(state.iterator..state.iterator + demand - 1, [])
      state = %{state | iterator: state.iterator + demand}
      IO.puts("sent: #{Enum.count(events)}")
      {:noreply, events, state}
    end
  end

  defmodule Consumer do
    use GenStage

    def start_link(opts) do
      GenStage.start_link(__MODULE__, opts, [name: __MODULE__])
    end

    def init(_) do
      {:consumer, %{}, subscribe_to: [Producer]}
    end

    def ask(demand) do
      GenStage.cast(__MODULE__, {:ask, demand})
    end

    def handle_subscribe(:producer, _options, from, _state) do
      state = %{producer: from}
      {:manual, state}
    end

    def handle_cast({:ask, demand}, state) do
      GenStage.ask(state.producer, demand)
      {:noreply, [], state}
    end

    def handle_events(events, _from, state) do
      IO.puts("received_count: #{Enum.count(events)}")
#      IO.puts("received_events: #{Enum.join(events, ",")}")
      Process.sleep(1_000)
      {:noreply, [], state}
    end
  end
end
