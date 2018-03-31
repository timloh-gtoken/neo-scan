ARG APP_NAME="timloh-gtoken-neo-scan"
ARG WORK_DIR="/opt/${APP_NAME}"

# Build
FROM elixir:1.6 as build

ARG APP_NAME
ARG WORK_DIR

COPY . .

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get update && \
    apt-get install -y inotify-tools nodejs && \
    mix local.hex --force && \
    mix local.rebar --force

RUN export MIX_ENV=prod && \
    mix deps.get && \
    cd apps/neoscan_web/assets && \
    npm install && \
    ./node_modules/brunch/bin/brunch b -p && \
    cd ../../.. && \
    mix phx.digest && \
    mix release

RUN RELEASE_NAME=`echo ${APP_NAME} | tr '-' '_'` && \
    RELEASE_DIR=`ls -d _build/prod/rel/${RELEASE_NAME}/releases/*/` && \
    mkdir /export && \
    tar -xf "${RELEASE_DIR}/${RELEASE_NAME}.tar.gz" -C /export

# Deployment
FROM debian:stretch

ARG APP_NAME
ARG WORK_DIR

ENV LANG=C.UTF-8

EXPOSE 4000
ENV REPLACE_OS_VARS=true \
    PORT=4000

RUN apt-get update && \
    apt-get install -y ca-certificates libodbc1 libssl1.1 libsctp1

RUN groupadd -r default && \
    useradd -r -g default default && \
    mkdir -p ${WORK_DIR} && \
    chown -R default:default ${WORK_DIR}

COPY --from=build /export/ ${WORK_DIR}

USER default
WORKDIR ${WORK_DIR}

ENTRYPOINT ["bin/timloh_gtoken_neo_scan"]
CMD ["foreground"]
