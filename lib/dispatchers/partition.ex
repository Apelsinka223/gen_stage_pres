defmodule Dispathers.Partition do
  defmodule Producer do
    use GenStage

    def start_link(_) do
      GenStage.start_link(__MODULE__, %{}, [name: __MODULE__])
    end

    def init(_) do
      {
        :producer,
        %{iterator: 0},
        dispatcher: {
          GenStage.PartitionDispatcher,
          partitions: [Dispathers.Partition.Consumer.A, Dispathers.Partition.Consumer.B],
          hash: fn event ->
            partition =
              if rem(event, 2) == 0 do
                Dispathers.Partition.Consumer.A
              else
                Dispathers.Partition.Consumer.B
              end

            {event, partition}
          end
        }
      }
    end

    def handle_demand(demand, state) do
      IO.puts("demanded: #{demand}")
      Process.sleep(1000)

      events = Enum.into(state.iterator..state.iterator + demand - 1, [])
      state = %{state | iterator: state.iterator + demand}
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
        %{},
        subscribe_to: [
          {Producer, min_demand: 0, max_demand: 10, partition: __MODULE__}
        ]
      }
    end

    def handle_events(events, _from, state) do
      IO.puts("#{state[:name]}: #{Enum.join(events, ",")}")
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
        subscribe_to: [
          {Producer, min_demand: 0, max_demand: 10, partition: __MODULE__}
        ]
      }
    end

    def handle_events(events, _from, state) do
      IO.puts("#{state[:name]}: #{Enum.join(events, ",")}")
      Process.sleep(1000)
      {:noreply, [], state}
    end
  end
end
