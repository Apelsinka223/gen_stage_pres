defmodule First do
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
      GenStage.start_link(__MODULE__, opts, opts)
    end

    def init(_) do
      {:consumer, %{}, subscribe_to: [{Producer, min_demand: 0, max_demand: 10}]}
    end

    def handle_events(events, _from, state) do
      IO.puts("received_count: #{Enum.count(events)}")
#      IO.puts("received_events: #{Enum.join(events, ",")}")
      Process.sleep(1_000)
      {:noreply, [], state}
    end
  end
end
