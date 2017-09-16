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

    ```
    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Poison
    ```

    Add the Appsignal.JSPlug to your endpoint.ex file.

    ```
    use Appsignal.Phoenix # Below the AppSignal (Phoenix) plug
    plug Appsignal.JSPlug
    ```

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
      start_transaction()
      |> set_action(conn)
      |> set_error(conn)
      |> complete_transaction(conn)

      send_resp(conn, 200, "")
    end
    def call(conn, _), do: conn

    defp start_transaction do
      Appsignal.Transaction.start(@transaction.generate_id, :frontend)
    end

    # Set a custom action for the JavaScript error
    defp set_action(transaction, conn) do
      case Map.fetch(conn.params, "action") do
        {:ok, action} -> @transaction.set_action(transaction, action)
        :error -> transaction
      end
    end

    defp set_error(transaction, conn) do
      # Required data for the error
      %{
        "name" => name,
        "message" => message,
        "backtrace" => backtrace,
      } = conn.params
      @transaction.set_error(transaction, name, message, backtrace)
    end

    defp set_environment(transaction, conn) do
      # Set environment, required field
      %{"environment" => environment} = conn.params
      @transaction.set_sample_data(transaction, "environment", environment)
    end

    defp set_params(transaction, conn) do
      # Only set params when available
      case Map.fetch(conn.params, "params") do
        {:ok, params} ->
          @transaction.set_sample_data(transaction, "params", params)
        :error -> transaction
      end
    end

    defp set_session_data(transaction, conn) do
      # Only fetch session data when necessary
      case config()[:skip_session_data] do
        false ->
          c = fetch_session(conn)
          case c.private[:plug_session_fetch] do
            # Only add it when the session has actually been fetched
            :done ->
              @transaction.set_sample_data(
                transaction,
                "session_data",
                c.private[:plug_session]
              )
            _ -> transaction
          end
        true -> transaction
      end
    end

    defp complete_transaction(transaction, conn) do
      transaction =
        case @transaction.finish(transaction) do
          :sample ->
            transaction
            |> set_environment(conn)
            |> set_params(conn)
            |> set_session_data(conn)
          _ -> transaction
        end
      :ok = @transaction.complete(transaction)
    end
  end
end
