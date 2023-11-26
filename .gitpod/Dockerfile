FROM gitpod/workspace-elixir:latest

ARG USERNAME=gitpod

# Get the public key store for and install erlang
RUN sudo curl -s https://packages.erlang-solutions.com/debian/erlang_solutions.asc | sudo apt-key add -
RUN sudo install-packages inotify-tools curl wget gnupg2 rubygems rename erlang erlang-dialyzer

# Node required to compile assets (webpack)
RUN curl -sL https://deb.nodesource.com/nsolid_setup_deb.sh | sudo bash /dev/stdin 20
RUN sudo install-packages nodejs

ENV MIX_HOME=/home/gitpod/.mix
ENV HEX_HOME=/home/gitpod/.hex

RUN mix local.hex --force && \
    mix local.rebar --force

# ?
# RUN mix archive.install hex phx_new --force

# From gitpod/workspace-images/chunks/tool-postgresql
ENV PGWORKSPACE="/workspace/.pgsql"
ENV PGDATA="$PGWORKSPACE/data"

# Install PostgreSQL 14 (not in ubuntu packages for this version)
RUN sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
RUN sudo install-packages postgresql-14 postgresql-contrib-14

# Setup PostgreSQL server for user gitpod
ENV PATH="/usr/lib/postgresql/14/bin:$PATH"

SHELL ["/usr/bin/bash", "-c"]
RUN PGDATA="${PGDATA//\/workspace/$HOME}" \
 && mkdir -p ~/.pg_ctl/bin ~/.pg_ctl/sockets $PGDATA \
 && initdb -D $PGDATA \
 && printf '#!/bin/bash\npg_ctl -D $PGDATA -l ~/.pg_ctl/log -o "-k ~/.pg_ctl/sockets" start\n' > ~/.pg_ctl/bin/pg_start \
 && printf '#!/bin/bash\npg_ctl -D $PGDATA -l ~/.pg_ctl/log -o "-k ~/.pg_ctl/sockets" stop\n' > ~/.pg_ctl/bin/pg_stop \
 && chmod +x ~/.pg_ctl/bin/*
ENV PATH="$HOME/.pg_ctl/bin:$PATH"
ENV DATABASE_URL="postgresql://gitpod@localhost"
ENV PGHOSTADDR="127.0.0.1"
ENV PGDATABASE="postgres"
COPY --chown=gitpod:gitpod .gitpod/postgresql-hook.bash $HOME/.bashrc.d/200-postgresql-launch

USER gitpod
