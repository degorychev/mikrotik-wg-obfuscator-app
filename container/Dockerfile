FROM clustermeerkat/wg-obfuscator:1.6 AS upstream

FROM alpine:3.22

LABEL org.opencontainers.image.title="WireGuard Obfuscator for MikroTik Apps" \
      org.opencontainers.image.description="RouterOS Apps wrapper for ClusterM/wg-obfuscator" \
      org.opencontainers.image.licenses="GPL-3.0-or-later"

RUN apk add --no-cache ca-certificates

COPY --from=upstream /app/wg-obfuscator /usr/local/bin/wg-obfuscator
COPY entrypoint.sh /usr/local/bin/wg-obfuscator-entrypoint
COPY THIRD_PARTY_NOTICES.md /usr/share/doc/wg-obfuscator-app/THIRD_PARTY_NOTICES.md

RUN chmod 0755 /usr/local/bin/wg-obfuscator /usr/local/bin/wg-obfuscator-entrypoint

ENTRYPOINT ["/usr/local/bin/wg-obfuscator-entrypoint"]
