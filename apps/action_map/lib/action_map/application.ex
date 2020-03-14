defmodule ActionMap.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  defp file_store_pool do
    [
      name: {:local, ActionMap.FileStorage.Pool},
      worker_module: ActionMap.FileStorage,
      size: 5,
      max_overflow: 2
    ]
  end

  def start(_type, _args) do
    children = [
      :poolboy.child_spec(:woker, file_store_pool()),
      {DynamicSupervisor, name: ActionMap.Supervisor, strategy: :one_for_one}
      # Starts a worker by calling: ActionMap.Worker.start_link(arg)
      # {ActionMap.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ActionMap.ApplicationSupervisor]
    Supervisor.start_link(children, opts)
  end
end
