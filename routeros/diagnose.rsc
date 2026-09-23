:local appName "wg-obfuscator-client"
:local wgName "wg-obf-easy"
:local peerName "wg-obf-easy-server"
:local routeComment "wg-obfuscator-app: vpn default route"
:local transportBypassComment "wg-obfuscator-app: transport bypass"
:local clientNatComment "wg-obfuscator-app: client NAT"

:put "=== WireGuard Obfuscator App diagnostics ==="

:local appId [/app find where name=$appName]
:if ([:len $appId] = 0) do={
    :put ("ERROR: App not found: " . $appName)
} else={
    :put ("App running=" . [/app get $appId running] . " status=" . [/app get $appId status] . " ip=" . [/app get $appId ip-address])
}

:local peerId [/interface wireguard peers find where name=$peerName]
:if ([:len $peerId] = 0) do={
    :put ("ERROR: WireGuard peer not found: " . $peerName)
} else={
    :put ("Peer disabled=" . [/interface wireguard peers get $peerId disabled])
    :put ("Endpoint=" . [/interface wireguard peers get $peerId current-endpoint-address] . ":" . [/interface wireguard peers get $peerId current-endpoint-port])
    :put ("Last handshake=" . [/interface wireguard peers get $peerId last-handshake])
    :put ("RX=" . [/interface wireguard peers get $peerId rx] . " TX=" . [/interface wireguard peers get $peerId tx])
}

:put "--- Managed route ---"
/ip route print detail where comment=$routeComment
:put "--- Transport bypass counters ---"
/ip firewall mangle print stats detail where comment=$transportBypassComment
:put "--- Client NAT counters ---"
/ip firewall nat print stats detail where comment=$clientNatComment
:put "--- Recent App/container log messages ---"
/log print where topics~"container" and message~"wg-obfuscator"

