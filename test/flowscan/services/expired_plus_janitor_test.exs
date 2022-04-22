defmodule Flowscan.Services.ExpiredPlusJanitorTest do
  @moduledoc false
  use Flowscan.DataCase
  alias Flowscan.AuditLog
  alias Flowscan.Repo
  alias Flowscan.Services.ExpiredPlusJanitor
  alias Flowscan.User
  import Ecto.Query

  describe "ExpiredPlusJanitor" do
    test "run/0 marks expired pro subscription users inactive and doesn't touch the rest" do
      insert(:user, is_plus: true, plus_expires_at: Faker.DateTime.forward(1))
      insert(:user, is_plus: true, plus_expires_at: Faker.DateTime.backward(1))
      insert(:user, is_plus: true, plus_expires_at: Faker.DateTime.backward(2))
      insert(:user, is_plus: false, plus_expires_at: Faker.DateTime.backward(1))

      assert length(User.expired_plus_users()) == 2
      ExpiredPlusJanitor.run()
      assert Enum.empty?(User.expired_plus_users())
      assert length(User |> where(is_plus: true) |> Repo.all()) == 1
      assert length(AuditLog |> where(type: "plus_subscription_expired") |> Repo.all()) == 2
    end
  end
end
