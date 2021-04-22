defmodule Dispathers.Demand do
  defmodule Producer do
    use GenStage

    def start_link(_) do
      GenStage.start_link(__MODULE__, %{}, [name: __MODULE__])
    end

    def init(_) do
      {:producer, %{iterator: 0, demand: 0}, dispatcher: GenStage.DemandDispatcher}
    end

    def handle_demand(demand, state) do
      IO.puts("demanded: #{demand}")
      Process.sleep(1_000)

      events = Enum.into(state.iterator..state.iterator + 1 - 1, [])
      state = %{state | iterator: state.iterator + demand, demand: demand - Enum.count(events)}

      Process.send_after(self(), :ready, 2_000)

      {:noreply, events, state}
    end

    def handle_info(:ready, state) do
      events = Enum.into(state.iterator..state.iterator + 1 - 1, [])
      state = %{state | demand: state.demand - Enum.count(events)}
      IO.puts("sent: #{Enum.count(events)}")

      Process.send_after(self(), :ready, 2_000)

      {:noreply, events, state}
    end
  end

  defmodule Consumer.A do
    use GenStage

    def start_link(opts) do
      GenStage.start_link(__MODULE__, opts, name: __MODULE__)
    end

    def init(_) do
      {
        :consumer,
        %{iterator: 0},
        subscribe_to: [{Producer, min_demand: 0, max_demand: 10}]
      }
    end

    def handle_events(events, _from, state) do
      IO.puts("#{__MODULE__} received_count: #{Enum.count(events)}")
#      IO.puts("#{__MODULE__} received_events: #{Enum.join(events, ",")}")
      Process.sleep(1000)
      {:noreply, [], state}
    end
  end

  defmodule Consumer.B do
    use GenStage

    def start_link(opts) do
      GenStage.start_link(__MODULE__, opts, name: __MODULE__)
    end

    def init(_) do
      {
        :consumer,
        %{},
        subscribe_to: [{Producer, min_demand: 0, max_demand: 100}]
      }
    end

    def handle_events(events, _from, state) do
      IO.puts("#{__MODULE__} received_count: #{Enum.count(events)}")
#      IO.puts("#{__MODULE__} received_events: #{Enum.join(events, ",")}")
      Process.sleep(1000)
      {:noreply, [], state}
    end
  end
end
