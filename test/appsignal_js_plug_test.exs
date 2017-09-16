defmodule Appsignal.JSPlugTest do
  use ExUnit.Case
  use Plug.Test
  doctest Appsignal.JSPlug

  alias Appsignal.FakeTransaction

  setup do
    FakeTransaction.start_link
    :ok
  end

  @default_opts [
    store: :cookie,
    key: "foobar",
    encryption_salt: "encrypted cookie salt",
    signing_salt: "signing salt",
    log: false
  ]

  @secret String.duplicate("abcdef0123456789", 8)
  @signing_opts Plug.Session.init(Keyword.put(@default_opts, :encrypt, false))

  def prepare_conn(conn) do
    put_in(conn.secret_key_base, @secret)
    |> Plug.Session.call(@signing_opts)
    |> put_req_header("content-type", "application/json")
    |> plug_parser
  end

  def plug_parser(conn) do
    opts = Plug.Parsers.init(
      parsers: [:urlencoded, :multipart, :json],
      pass: ["application/json"],
      json_decoder: Poison
    )
    Plug.Parsers.call(conn, opts)
  end

  def send_request(conn) do
    Appsignal.JSPlug.call(conn, [])
  end

  test "normal request with minimal data" do
    conn(
      :post,
      "/appsignal_error_catcher",
      """
      {
        "name": "MyError",
        "message": "My error message",
        "backtrace": [
          "foo/bar.js:1",
          "foo/baz.js:10"
        ],
        "environment": {
          "agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6)",
          "platform": "MacIntel"
        }
      }
      """
    )
    |> prepare_conn
    |> send_request

    assert FakeTransaction.action == nil
    assert FakeTransaction.sample_data == %{
      "environment" => %{
        "agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6)",
        "platform" => "MacIntel"
      },
      "session_data" => %{}
    }
    assert [
      {
        _,
        "MyError",
        "My error message",
        ["foo/bar.js:1", "foo/baz.js:10"]
      }
    ] = FakeTransaction.errors
  end

  test "request with params" do
    conn(
      :post,
      "/appsignal_error_catcher",
      """
      {
        "name": "MyError",
        "message": "My error message",
        "backtrace": [
          "foo/bar.js:1",
          "foo/baz.js:10"
        ],
        "environment": {
          "agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6)",
          "platform": "MacIntel"
        },
        "params": {
          "foo": "bar",
          "baz": 10
        }
      }
      """
    )
    |> prepare_conn
    |> send_request

    assert FakeTransaction.action == nil
    assert FakeTransaction.sample_data == %{
      "environment" => %{
        "agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6)",
        "platform" => "MacIntel"
      },
      "params" => %{
        "foo" => "bar",
        "baz" => 10
      },
      "session_data" => %{}
    }
  end

  test "request with action" do
    conn(
      :post,
      "/appsignal_error_catcher",
      """
      {
        "name": "MyError",
        "message": "My error message",
        "backtrace": [
          "foo/bar.js:1",
          "foo/baz.js:10"
        ],
        "environment": {
          "agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6)",
          "platform": "MacIntel"
        }
      }
      """
    )
    |> prepare_conn
    |> send_request

    assert FakeTransaction.action == nil
    assert FakeTransaction.sample_data == %{
      "environment" => %{
        "agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6)",
        "platform" => "MacIntel"
      },
      "session_data" => %{}
    }
  end

  test "request with session data" do
    conn(
      :post,
      "/appsignal_error_catcher",
      """
      {
        "name": "MyError",
        "message": "My error message",
        "backtrace": [
          "foo/bar.js:1",
          "foo/baz.js:10"
        ],
        "environment": {
          "agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6)",
          "platform": "MacIntel"
        }
      }
      """
    )
    |> prepare_conn
    |> fetch_session
    |> put_session("session", "foo")
    |> put_session("data", 10)
    |> send_request

    assert FakeTransaction.action == nil
    assert FakeTransaction.sample_data == %{
      "environment" => %{
        "agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6)",
        "platform" => "MacIntel"
      },
      "session_data" => %{"session" => "foo", "data" => 10}
    }
  end

  describe "with session data collection disabled" do
    setup do
      original_config = Application.get_env(:appsignal, :config, %{})
      config = Map.put(original_config, :skip_session_data, true)
      Application.put_env(:appsignal, :config, config)

      on_exit(fn ->
        Application.put_env(:appsignal, :config, original_config)
      end)
      :ok
    end

    test "does not set session data on transaction" do
      conn(
        :post,
        "/appsignal_error_catcher",
        """
        {
          "name": "MyError",
          "message": "My error message",
          "backtrace": [
            "foo/bar.js:1",
            "foo/baz.js:10"
          ],
          "environment": {
            "agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6)",
            "platform": "MacIntel"
          }
        }
        """
      )
      |> prepare_conn
      |> send_request

      assert FakeTransaction.sample_data == %{
        "environment" => %{
          "agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6)",
          "platform" => "MacIntel"
        }
      }
    end
  end
end
