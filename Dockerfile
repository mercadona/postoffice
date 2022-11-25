# BUILD
FROM elixir:1.14.1-alpine as build

RUN apk add --no-cache --update make g++ nodejs npm

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV prod

WORKDIR /app

COPY . .

RUN mix deps.get --only prod
RUN cd assets && npm install && cd -
RUN npm run deploy --prefix ./assets
RUN mix phx.digest
RUN mix release --quiet

# RELEASE
FROM alpine:3.16

RUN apk add --no-cache --update bash openssl libgcc libstdc++ ncurses-libs

COPY config/dummy-credentials.json /secrets/dummy-credentials.json
ENV GOOGLE_APPLICATION_CREDENTIALS /secrets/dummy-credentials.json

WORKDIR /app

COPY --from=build /app/_build/prod/rel/postoffice ./

CMD ["start"]
ENTRYPOINT ["/app/bin/postoffice"]