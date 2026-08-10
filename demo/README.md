# Humanizer LiveView Demo

An independent Phoenix LiveView application that showcases every public
Humanizer formatter and option in one interactive, English-language playground.
It uses the checked-out library through `{:humanizer, path: ".."}`; it is not
part of the Humanizer Hex package.

## Run locally

From the repository root:

```sh
cd demo
mix setup
mix phx.server
```

Open [http://localhost:4000](http://localhost:4000). The app has no database,
accounts, external services, or runtime CDN dependencies.

Run its checks with:

```sh
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix assets.deploy
```

## Build a production release

```sh
cd demo
MIX_ENV=prod mix deps.get --only prod
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release --overwrite
SECRET_KEY_BASE="$(mix phx.gen.secret)" \
  PHX_HOST=localhost \
  PORT=4000 \
  PHX_SERVER=true \
  _build/prod/rel/humanizer_demo/bin/humanizer_demo start
```

Production startup requires `SECRET_KEY_BASE`. `PHX_HOST` defaults to
`example.com`, `PORT` defaults to `4000`, and `PHX_SERVER` enables the endpoint
when the release is started directly. The generated `bin/server` overlay sets
`PHX_SERVER` automatically.

## Build and run the container

The path dependency means the Docker build context must be the repository root:

```sh
docker build -f demo/Dockerfile -t humanizer-demo .
docker run --rm \
  --name humanizer-demo \
  -p 4000:4000 \
  -e SECRET_KEY_BASE="$(mix phx.gen.secret)" \
  -e PHX_HOST=localhost \
  humanizer-demo
```

The final image contains the release rather than the source tree, runs as the
unprivileged `humanizer` user, exposes port `4000`, and checks `GET /health` for
readiness.

```sh
curl --fail http://localhost:4000/health
```

## Environment

| Variable | Purpose | Default |
|---|---|---|
| `SECRET_KEY_BASE` | Signs and encrypts Phoenix session data | Required in production |
| `PHX_HOST` | Public hostname used in generated URLs | `example.com` |
| `PORT` | HTTP listening port | `4000` |
| `PHX_SERVER` | Enables the endpoint in a direct release start | Unset |

This demo deliberately remains English-only, matching Humanizer's output
contract. User inputs are parsed as values and are never evaluated as Elixir.
