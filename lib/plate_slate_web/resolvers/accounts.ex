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
end
