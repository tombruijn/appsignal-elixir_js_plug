require Appsignal
appsignal = Application.get_env(:appsignal, :appsignal, Appsignal)
if appsignal.plug? do
  require Logger

  defmodule Appsignal.JSPlug do
    import Plug.Conn
    use Appsignal.Config

    @transaction Application.get_env(:appsignal, :appsignal_transaction, Appsignal.Transaction)

    @moduledoc """
    A plug for sending JavaScript errors to AppSignal.

    ## Phoenix usage

    Add the following parser to your router.

        plug Plug.Parsers,
          parsers: [:urlencoded, :multipart, :json],
          pass: ["*/*"],
          json_decoder: Poison

    Add the Appsignal.JSPlug to your endpoint.ex file.

        use Appsignal.Phoenix # Below the AppSignal (Phoenix) plug
        plug Appsignal.JSPlug

    Now send the errors with a POST request to the `/appsignal_error_catcher`
    endpoint.

    Required JSON payload fields are:

    - `name` - `String` - the error name.
    - `message` - `String` - the error message.
    - `backtrace` - `List<String>` - the error backtrace. A list of `String`s
      with lines and linenumbers.
    - `environment` - `Map<String, any>` - a `Map` of environment values that
      are relevant to the error. Such as the browser type and version, the
      user's Operating System, screen width and height.

    Optional fields are:

    - `action` - `String` - the action name in which the error occured.
    - `params` - `Map<String, any>` - a `Map` of parameters for this action,
      function or page request params.

    For more information see the AppSignal Front-end error handling Beta docs:
    https://docs.appsignal.com/front-end/error-handling.html
    """

    def init(_) do
      Logger.debug("Initializing Appsignal.JSPlug")
    end

    def call(%Plug.Conn{request_path: "/appsignal_error_catcher", method: "POST"} = conn, _) do
      record_transaction(conn)
      send_resp(conn, 200, "")
    end
    def call(conn, _), do: conn

    defp record_transaction(conn) do
      # Required data for the error
      %{
        "name" => name,
        "message" => message,
        "backtrace" => backtrace,
        "environment" => environment,
      } = data = conn.params

      transaction =
        Appsignal.Transaction.start(@transaction.generate_id, :frontend)
        |> @transaction.set_error(name, message, backtrace)

      # Set a custom action for the JavaScript error
      transaction =
        case Map.fetch(data, "action") do
          {:ok, action} ->
            @transaction.set_action(transaction, action)
          :error -> transaction
        end

      case @transaction.finish(transaction) do
        :sample ->
          transaction
          |> @transaction.set_sample_data("environment", environment)

          # Only set params when available
          if Map.has_key?(data, "params") do
            {:ok, p} = Map.fetch(data, "params")
            @transaction.set_sample_data(transaction, "params", p)
          end

          # Only fetch session data when necessary
          if !config()[:skip_session_data] do
            c = fetch_session(conn)
            # Only add it when the session has actually been fetched
            if c.private[:plug_session_fetch] == :done do
              @transaction.set_sample_data(
                transaction, "session_data", c.private[:plug_session]
              )
            end
          end
      end
      :ok = @transaction.complete(transaction)
    end
  end
end
