# syntax=docker/dockerfile:1

ARG WYOMING_VOSK_VERSION=1.5.0

# -----------------------------------------------------------------------------
# Build stage: install wyoming-vosk into a virtualenv
# -----------------------------------------------------------------------------
# Pinned by digest; Dependabot keeps tag and digest up to date
FROM python:3.12-slim-trixie@sha256:aa943ce411423c7582288f18707ff66eddcbaeb510502d747a72aeb34f30d159 AS build

ARG WYOMING_VOSK_VERSION

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
        "wyoming-vosk[limited] @ https://github.com/rhasspy/wyoming-vosk/archive/refs/tags/v${WYOMING_VOSK_VERSION}.tar.gz"

# -----------------------------------------------------------------------------
# Runtime stage
# -----------------------------------------------------------------------------
FROM python:3.12-slim-trixie@sha256:aa943ce411423c7582288f18707ff66eddcbaeb510502d747a72aeb34f30d159

ARG WYOMING_VOSK_VERSION

RUN apt-get update \
    && apt-get install -y --no-install-recommends libatomic1 \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1000 vosk \
    && useradd --uid 1000 --gid vosk --no-create-home --shell /usr/sbin/nologin vosk \
    && mkdir -p /data /share/vosk/models /share/vosk/sentences \
    && chown -R vosk:vosk /data /share/vosk

COPY --from=build /opt/venv /opt/venv
COPY --chmod=755 start.sh /start.sh

ENV PATH="/opt/venv/bin:${PATH}" \
    PYTHONUNBUFFERED=1 \
    WYOMING_VOSK_VERSION=${WYOMING_VOSK_VERSION}

VOLUME ["/data", "/share/vosk/models", "/share/vosk/sentences"]
EXPOSE 10300

# Python only exits cleanly on SIGINT when running as PID 1
STOPSIGNAL SIGINT

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD ["python3", "-c", "import socket; socket.create_connection(('127.0.0.1', 10300), timeout=3).close()"]

ENTRYPOINT ["/start.sh"]
