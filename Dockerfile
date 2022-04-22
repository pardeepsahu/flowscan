FROM elixir:1.12.2-alpine

# Install debian packages
RUN apk update
RUN apk add --no-cache inotify-tools postgresql-client make gcc libc-dev

# Install Phoenix packages
RUN mix local.hex --force
RUN mix local.rebar --force

WORKDIR /app
EXPOSE 4000