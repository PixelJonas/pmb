FROM alpine:3.16.0@sha256:686d8c9dfa6f3ccfc8230bc3178d23f84eeaf7e457f36f271ab1acc53015037c

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG GOCRON_VERSION="v0.0.10"

ENV \
  PMB__CRON_SCHEDULE="@daily" \
  PMB__CRON_HEALTHCHECK_PORT=18080 \
  PMB__SOURCE="**None**" \
  PMB__DESTINATION="**None**"\
  PMB__KEEP_DAYS=7 \
  PMB__KEEP_WEEKS=1 \
  PMB__KEEP_MONTHS=0 \
  PMB__KEEP_MINS=1440 \
  RCLONE_CONFIG="/app/rclone.conf"

WORKDIR /app

USER root

#hadolint ignore=DL3018,DL4006
RUN \
    apk add --no-cache \
        bash \
        ca-certificates \
        curl \
        nano \
        rclone \
        tzdata \
    && \
    case "${TARGETPLATFORM}" in \
        'linux/amd64') export ARCH='amd64' ;; \
        'linux/arm64') export ARCH='arm64' ;; \
    esac \
    && curl -L https://github.com/prodrigestivill/go-cron/releases/download/${GOCRON_VERSION}/go-cron-linux-${ARCH}-static.gz | zcat > /usr/local/bin/go-cron \
    && chmod +x /usr/local/bin/go-cron \
    && addgroup -S pmb --gid 1002 \
    && adduser -S pmb -G pmb --uid 1002 \
    && mkdir -p /app \
    && chown -R pmb:pmb /app \
    && chmod -R 775 /app \
    && rm -rf /tmp/*

COPY ./script/backup.sh /app/backup.sh
COPY ./entrypoint.sh /entrypoint.sh

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER pmb

ENTRYPOINT [ "/entrypoint.sh" ]

HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f "http://localhost:$PMB__CRON_HEALTHCHECK_PORT/" || exit 1