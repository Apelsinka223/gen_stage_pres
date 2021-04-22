defmodule ForwardPressure do
  defmodule Producer do
    use GenStage

    def start_link(_) do
      GenStage.start_link(__MODULE__, %{}, [name: __MODULE__])
    end

    def init(_) do
      Process.send_after(self(), :timeout, 1_000)
      {:producer, %{iterator: 0}}
    end

    def handle_demand(demand, state) do
      IO.puts("demanded: #{demand}")
      {:noreply, [], state}
    end

    def handle_info(:timeout, state) do
      Process.send_after(self(), :timeout, 1_000)
      IO.puts("sent: 2000")
      {:noreply, Enum.into(1..2000, []), state}
    end
  end

  defmodule Consumer do
    use GenStage

    def start_link(opts) do
      GenStage.start_link(__MODULE__, opts, opts)
    end

    def init(_) do
      {:consumer, %{}, subscribe_to: [Producer]}
    end

    def handle_events(events, _from, state) do
      IO.puts("received_count: #{Enum.count(events)}")
#      IO.puts("received_events: #{Enum.join(events, ",")}")
      Process.sleep(1_000)
      {:noreply, [], state}
    end
  end
end
