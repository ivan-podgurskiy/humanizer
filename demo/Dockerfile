ARG ELIXIR_VERSION=1.18.3
ARG OTP_VERSION=27.3.4.12
ARG DEBIAN_VERSION=trixie-20260610-slim

ARG BUILDER_IMAGE="docker.io/hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="docker.io/debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force \
  && mix local.rebar --force

ENV MIX_ENV=prod

# Keep the Humanizer path dependency at /app and build its independent demo
# from /app/demo. The Docker build context must therefore be the repository root.
COPY mix.exs mix.lock .formatter.exs README.md ROADMAP.md CHANGELOG.md LICENSE ./
COPY lib lib
COPY demo/mix.exs demo/mix.lock demo/

WORKDIR /app/demo
RUN mix deps.get --only ${MIX_ENV}

RUN mkdir config
COPY demo/config/config.exs demo/config/prod.exs config/
RUN mix deps.compile
RUN mix assets.setup

COPY demo/priv priv
COPY demo/lib lib
RUN mix compile

COPY demo/assets assets
RUN mix assets.deploy

COPY demo/config/runtime.exs config/
COPY demo/rel rel
RUN mix release

FROM ${RUNNER_IMAGE} AS final

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl libncurses6 libstdc++6 locales openssl \
  && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
  && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV MIX_ENV=prod
ENV PORT=4000

WORKDIR /app
RUN groupadd --system humanizer \
  && useradd --system --gid humanizer --home-dir /app --shell /usr/sbin/nologin humanizer \
  && chown humanizer:humanizer /app

COPY --from=builder --chown=humanizer:humanizer /app/demo/_build/prod/rel/humanizer_demo ./

USER humanizer

EXPOSE 4000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl --fail --silent --show-error "http://127.0.0.1:${PORT}/health" || exit 1

CMD ["/app/bin/server"]
