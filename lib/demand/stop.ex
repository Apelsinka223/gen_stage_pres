defmodule Demand.Stop do
  defmodule Producer do
    use GenStage

    def start_link(_) do
      GenStage.start_link(__MODULE__, %{}, [name: __MODULE__])
    end

    def init(_) do
      {:producer, %{iterator: 0, demand: 0, stop: false}}
    end

    def stop, do: GenStage.cast(__MODULE__, :stop)

    def resume, do: GenStage.cast(__MODULE__, :resume)

    def handle_demand(demand, %{stop: false} = state) do
      IO.puts("demanded: #{demand}")
      Process.sleep(1_000)

      events = Enum.into(state.iterator..state.iterator + demand - 1, [])

      {:noreply, events, state}
    end

    def handle_demand(demand, %{stop: true} = state) do
      IO.puts("demanded: #{demand}")
      Process.sleep(1_000)

      state = %{state | demand: state.demand + demand}

      {:noreply, [], state}
    end

    def handle_cast(:stop, state) do
      IO.puts("stopped")
      {:noreply, [], %{state | stop: true}}
    end

    def handle_cast(:resume, state) do
      events = Enum.into(state.iterator..state.iterator + state.demand - 1, [])
      state = %{state | stop: false, demand: 0}
      IO.puts("resumed")
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
