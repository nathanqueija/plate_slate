defmodule PlateSlateWeb.Resolvers.Accounts do
  alias PlateSlate.Accounts

  def login(_, %{email: email, password: password, role: role}, _) do
    case Accounts.authenticate(role, email, password) do
      {:ok, user, jwt} ->
        {:ok, %{token: jwt, user: user}}

      _ ->
        {:error, "Incorrect email or password"}
    end
  end

  def me(_, _, %{content: %{current_user: current_user}}) do
    {:ok, current_user}
  end

  def me(_, _, _) do
    {:ok, nil}
  end
end
