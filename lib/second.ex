defmodule Second do
  defmodule Producer do
    use GenStage

    def start_link(_) do
      GenStage.start_link(__MODULE__, %{}, [name: __MODULE__])
    end

    def init(_) do
      {:producer, %{demand: 0, iterator: 0}}
    end

    def handle_demand(demand, state) do
      IO.puts("demanded: #{demand}")
      Process.sleep(1_000)

      events = Enum.into(state.iterator..state.iterator + (demand - 1) - 1, [])
      state = %{iterator: state.iterator + Enum.count(events), demand: demand - Enum.count(events)}
      IO.puts("sent: #{Enum.count(events)}")

      Process.send_after(self(), :ready, 2_000)

      {:noreply, events, state}
    end

    def handle_info(:ready, state) do
      events = Enum.into(state.iterator..state.iterator + state.demand - 1, [])
      state = %{state | demand: 0}
      IO.puts("sent_handle_info: #{Enum.count(events)}")
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
