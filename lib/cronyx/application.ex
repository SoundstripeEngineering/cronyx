defmodule Cronyx.Application do
  @moduledoc false

  # def start do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Cronyx.QueueManager,
      :poolboy.child_spec(:worker, poolboy_config())
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cronyx.Supervisor]

    Supervisor.start_link(children, opts)
  end

  defp poolboy_config do
    [
      name: {:local, :worker_pool},
      worker_module: Cronyx.Worker,
      size: fetch_worker_size(),
      max_overflow: 10
    ]
  end

  def fetch_worker_size do
    Application.get_env(:cronyx, :worker_size, 20)
  end
end
