# AppSignal for Elixir JavaScript Plug

A plug for sending JavaScript errors to AppSignal. Works for Phoenix and
Plug-only apps.

**Note:** This is not an official AppSignal package. It's is not supported by
AppSignal. Use at your own risk.

- [AppSignal.com website](https://appsignal.com/)
- [AppSignal for Elixir documentation](http://docs.appsignal.com/elixir/)
- AppSignal for [Front-end error handling] (Beta) documentation

## Usage

Add the following parser to your endpoint.ex file.

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  json_decoder: Poison

plug Appsignal.JSPlug # Above your app's router plug
plug MyExampleApp.Router
```

Now send the errors with a POST request to the `/appsignal_error_catcher`
endpoint. An example JavaScript is provided on the AppSignal docs website in
the [Front-end error handling] section.

For more information see the AppSignal [Front-end error handling] Beta docs.

## Installation

Make sure to install the [AppSignal for Elixir] package first by following the
[installation guide].

After having successfully installed AppSignal add `appsignal_js_plug` to your
list of dependencies in `mix.exs`.

```elixir
# mix.exs
def deps do
  [
    {:appsignal, ">= 1.3.0"},
    {:appsignal_js_plug, "~> 0.2"}
  ]
end
```

Then run `mix deps.get`.

## Configuration

### `filter_parameters`

This package listens to the AppSignal for Elixir [`filter_parameters`
configuration option]. If this option is set, all parameters values matching a
key name from the configuration will be replaced with `[FILTERED]`.

```elixir
# config/appsignal.exs
config :appsignal, :config, filter_parameters: ["password"]
```

### `skip_session_data`

This package listens to the AppSignal for Elixir [`skip_session_data`
configuration option]. If this option is set to `true`, no session data will be
added to the JavaScript errors.

```elixir
# config/appsignal.exs
config :appsignal, :config, skip_session_data: true
```

## Development

### Testing

Package testing is done with ExUnit and can be run with the `mix test` command.
You can also supply a path to a specific file path you want to test and even a
specific line on which the test you want to run is defined.

```sh
mix deps.get
mix test
mix test test/appsignal/some_test.ex:123
```

### Publishing new versions

1. Merge the `develop` branch to `master` if necessary.
2. Update the version number in `mix.exs`, e.g. `1.2.3`
3. Commit the change.
4. Tag the commit with the version number: `git tag 1.2.3`
5. Push the changes: `git push origin master 1.2.3`
6. Publish the package: `mix hex.publish`

## License

The AppSignal for Elixir JavaScript Plug package source code is released under
the MIT License. Check the [LICENSE](LICENSE) file for more information.

[AppSignal for Elixir]: https://github.com/appsignal/appsignal-elixir
[installation guide]: https://docs.appsignal.com/elixir/installation.html
[Front-end error handling]: https://docs.appsignal.com/front-end/error-handling.html
[`skip_session_data` configuration option]: https://docs.appsignal.com/elixir/configuration/options.html#appsignal_skip_session_data-skip_session_data
[`filter_parameters` configuration option]: https://docs.appsignal.com/elixir/configuration/parameter-filtering.html
