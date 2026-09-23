#!/bin/sh
set -eu

SOURCE_PORT="${WG_OBF_SOURCE_PORT:-13255}"
TARGET="${WG_OBF_TARGET:-}"
KEY="${WG_OBF_KEY:-}"
MASKING="${WG_OBF_MASKING:-STUN}"
VERBOSE="${WG_OBF_VERBOSE:-INFO}"
IN_TIMEOUT="${WG_OBF_IN_TIMEOUT:-30}"

fail() {
    printf 'wg-obfuscator-app: %s\n' "$1" >&2
    exit 1
}

case "$SOURCE_PORT" in
    ''|*[!0-9]*) fail "WG_OBF_SOURCE_PORT must be a number" ;;
esac
[ "$SOURCE_PORT" -ge 1 ] && [ "$SOURCE_PORT" -le 65535 ] || \
    fail "WG_OBF_SOURCE_PORT must be between 1 and 65535"

[ -n "$TARGET" ] || fail "WG_OBF_TARGET is required (host:port)"
[ -n "$KEY" ] || fail "WG_OBF_KEY is required"
[ "${#KEY}" -le 255 ] || fail "WG_OBF_KEY must be at most 255 characters"

if printf '%s\n%s\n' "$TARGET" "$KEY" | grep -q '[[:cntrl:]]'; then
    fail "WG_OBF_TARGET and WG_OBF_KEY must not contain control characters"
fi

case "$MASKING" in
    STUN|NONE|AUTO) ;;
    *) fail "WG_OBF_MASKING must be STUN, NONE, or AUTO" ;;
esac

case "$VERBOSE" in
    ERRORS|WARNINGS|INFO|DEBUG|TRACE) ;;
    *) fail "WG_OBF_VERBOSE must be ERRORS, WARNINGS, INFO, DEBUG, or TRACE" ;;
esac

case "$IN_TIMEOUT" in
    ''|*[!0-9]*) fail "WG_OBF_IN_TIMEOUT must be a non-negative integer" ;;
esac

umask 077
mkdir -p /run/wg-obfuscator
cat > /run/wg-obfuscator/wg-obfuscator.conf <<EOF
[main]
source-lport = ${SOURCE_PORT}
target = ${TARGET}
key = ${KEY}
masking = ${MASKING}
verbose = ${VERBOSE}
in-timeout = ${IN_TIMEOUT}
EOF

printf 'wg-obfuscator-app: target=%s source-port=%s masking=%s verbose=%s\n' \
    "$TARGET" "$SOURCE_PORT" "$MASKING" "$VERBOSE"

exec /usr/local/bin/wg-obfuscator -c /run/wg-obfuscator/wg-obfuscator.conf

