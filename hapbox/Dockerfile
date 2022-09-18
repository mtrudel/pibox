FROM elixir:latest

WORKDIR /app

COPY . .

RUN export MIX_ENV=prod && \
    rm -Rf _build && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix release

WORKDIR _build/prod/rel/hapbox

ENTRYPOINT ["./bin/hapbox"]
CMD ["start"]
