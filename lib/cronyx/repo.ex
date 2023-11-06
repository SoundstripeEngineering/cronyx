defmodule Cronyx.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :cronyx,
    adapter: Ecto.Adapters.Postgres

  def repo do
    Application.get_env(:cronyx, :repo, Cronyx.Repo)
  end

  def repo_ready? do
    Ecto.Repo.all_running()
    |> Enum.any?()
  end

  def table_exists?(table_name) do
    query = """
    SELECT to_regclass('#{table_name}');
    """

    case repo().query(query) do
      {:ok, %Postgrex.Result{rows: [[nil]]}} -> false
      {:ok, _} -> true
      {:error, _} -> false
    end
  end
end
