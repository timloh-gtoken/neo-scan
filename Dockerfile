ARG APP_NAME="timloh-gtoken-neo-scan"
ARG WORK_DIR="/opt/${APP_NAME}"

# Build
FROM elixir:1.6-slim as build

ARG APP_NAME
ARG WORK_DIR

COPY . .

RUN apt-get update && \
    apt-get install -y curl git-core inotify-tools build-essential && \
    mix local.hex --force && \
    mix local.rebar --force
    
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get update && \
    apt-get install nodejs

RUN export MIX_ENV=prod && \
    mix deps.get && \
    cd apps/neoscan_web/assets && \
    npm install && \
    ./node_modules/brunch/bin/brunch b -p && \
    cd .. && \
    mkdir -p priv/static && \
    cd ../.. && \
    mix phx.digest assets -o priv/static && \
    mix release

RUN RELEASE_NAME=`echo ${APP_NAME} | tr '-' '_'` && \
    RELEASE_DIR=`ls -d _build/prod/rel/${RELEASE_NAME}/releases/*/` && \
    mkdir /export && \
    tar -xf "${RELEASE_DIR}/${RELEASE_NAME}.tar.gz" -C /export

# Deployment
FROM debian:jessie

ARG APP_NAME
ARG WORK_DIR

ENV LANG=C.UTF-8

EXPOSE 4000
ENV REPLACE_OS_VARS=true \
    PORT=4000

RUN apt-get update && \
    apt-get install -y ca-certificates libodbc1 libssl1.0.0 libsctp1

RUN groupadd -r default && \
    useradd -r -g default default && \
    mkdir -p ${WORK_DIR} && \
    chown -R default:default ${WORK_DIR}

COPY --from=build /export/ ${WORK_DIR}

USER default
WORKDIR ${WORK_DIR}

ENTRYPOINT ["bin/timloh_gtoken_neo_scan"]
CMD ["start"]
