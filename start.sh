#!/usr/bin/env bash
set -euo pipefail

# Returns success for true/1/yes/on (case-insensitive)
is_true() {
    case "${1,,}" in
        true | 1 | yes | on) return 0 ;;
        *) return 1 ;;
    esac
}

# When started as root, make the writable directories usable for the
# unprivileged user and drop privileges.
if [ "$(id -u)" = "0" ]; then
    PUID="${PUID:-1000}"
    PGID="${PGID:-1000}"
    if [ -n "${MODEL_URL:-}" ]; then
        # Only the top-level models directory, existing models stay untouched
        chown "${PUID}:${PGID}" /share/vosk/models \
            || echo "WARNING: could not change ownership of /share/vosk/models" >&2
    fi
    find /data /share/vosk/sentences \
        \( ! -user "${PUID}" -o ! -group "${PGID}" \) \
        -exec chown "${PUID}:${PGID}" {} + \
        || echo "WARNING: could not change ownership of /data or /share/vosk/sentences" >&2
    exec setpriv --reuid="${PUID}" --regid="${PGID}" --clear-groups \
        env HOME=/tmp "$0" "$@"
fi

CORRECT_SENTENCES="${CORRECT_SENTENCES:-0.0}"
PRELOAD_LANGUAGE="${PRELOAD_LANGUAGE:-en}"
DEBUG_LOGGING="${DEBUG_LOGGING:-false}"
LIMIT_SENTENCES="${LIMIT_SENTENCES:-false}"
ALLOW_UNKNOWN="${ALLOW_UNKNOWN:-false}"

flags=()

if is_true "${DEBUG_LOGGING}"; then
    flags+=('--debug')
fi

if is_true "${LIMIT_SENTENCES}"; then
    flags+=('--limit-sentences')
fi

if is_true "${ALLOW_UNKNOWN}"; then
    flags+=('--allow-unknown')
fi

echo "WYOMING_VOSK_VERSION = ${WYOMING_VOSK_VERSION:-unknown}"
echo "CORRECT_SENTENCES    = ${CORRECT_SENTENCES}"
echo "PRELOAD_LANGUAGE     = ${PRELOAD_LANGUAGE}"
echo "DEBUG_LOGGING        = ${DEBUG_LOGGING}"
echo "LIMIT_SENTENCES      = ${LIMIT_SENTENCES}"
echo "ALLOW_UNKNOWN        = ${ALLOW_UNKNOWN}"
echo "MODEL_URL            = ${MODEL_URL:-}"

if [ -n "${MODEL_URL:-}" ]; then
    python3 /download_model.py "${MODEL_URL}" "/share/vosk/models/${PRELOAD_LANGUAGE}"
fi

if [ -d '/share/vosk/models' ]; then
    # Each directory is a language name with a model inside
    while read -r lang_dir; do
        # Override the model for this language
        lang="$(basename "${lang_dir}")"
        flags+=('--model-for-language' "${lang}" "$(realpath "${lang_dir}")")
    done < <(find '/share/vosk/models' -mindepth 1 -maxdepth 1 -type d)
fi

echo "flags = ${flags[*]}"
exec python3 -m wyoming_vosk \
    --uri 'tcp://0.0.0.0:10300' \
    --download-dir /data \
    --data-dir /share/vosk/models \
    --sentences-dir /share/vosk/sentences \
    --correct-sentences "${CORRECT_SENTENCES}" \
    --language "${PRELOAD_LANGUAGE}" \
    --preload-language "${PRELOAD_LANGUAGE}" \
    "${flags[@]}" \
    "$@"
