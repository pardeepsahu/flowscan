FROM elixir:1.10

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install --yes build-essential postgresql-client inotify-tools

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix archive.install hex phx_new 1.5.3

WORKDIR /app
EXPOSE 4000