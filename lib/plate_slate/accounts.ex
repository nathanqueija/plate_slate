defmodule PlateSlate.Accounts do
  @moduledoc """
  Accounts context
  """

  import Ecto.Query, warn: false
  alias PlateSlate.Repo

  alias PlateSlate.Accounts.User
  alias PlateSlate.Guardian

  import Bcrypt, only: [verify_pass: 2]

  def authenticate(role, email, password) do
    user = Repo.get_by(User, role: to_string(role), email: email)

    with {:ok, user} <- verify_password(password, user),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      {:ok, user, token}
    else
      _ -> :error
    end
  end

  def get_user!(id), do: Repo.get!(User, id)

  defp verify_password(password, %User{} = user) when is_binary(password) do
    if verify_pass(password, user.password_hash) do
      {:ok, user}
    else
      {:error, :invalid_password}
    end
  end

  defp verify_password(_, _) do
    :error
  end
end
