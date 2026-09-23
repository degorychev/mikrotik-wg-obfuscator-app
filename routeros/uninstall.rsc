# Removes only RouterOS objects created by install.template.rsc.
# The App and its stored data are intentionally preserved.

:local wgName "wg-obf-easy"
:local peerName "wg-obf-easy-server"
:local routeComment "wg-obfuscator-app: vpn default route"
:local transportBypassComment "wg-obfuscator-app: transport bypass"
:local clientNatComment "wg-obfuscator-app: client NAT"

/ip route remove [find where comment=$routeComment]
/ip firewall mangle remove [find where comment=$transportBypassComment]
/ip firewall nat remove [find where comment=$clientNatComment]
/interface wireguard peers remove [find where name=$peerName and comment="wg-obfuscator-app"]
/ip address remove [find where interface=$wgName and comment="wg-obfuscator-app"]
/interface wireguard remove [find where name=$wgName and comment="wg-obfuscator-app"]

:put "RouterOS integration removed. The App itself was not deleted."

