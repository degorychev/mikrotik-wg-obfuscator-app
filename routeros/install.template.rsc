# WireGuard Obfuscator App - RouterOS integration installer
# RouterOS 7.22+
#
# 1. Replace every CHANGE_ME value below.
# 2. Import this file after the App is installed and running.
# 3. Delete the uploaded file after a successful import because it contains a private key.

:local appName "wg-obfuscator-client"
:local wgName "wg-obf-easy"
:local peerName "wg-obf-easy-server"
:local routeComment "wg-obfuscator-app: vpn default route"
:local transportBypassComment "wg-obfuscator-app: transport bypass"
:local clientNatComment "wg-obfuscator-app: client NAT"

:local privateKey "CHANGE_ME_CLIENT_PRIVATE_KEY"
:local serverPublicKey "CHANGE_ME_SERVER_PUBLIC_KEY"
:local serverTransportIP "CHANGE_ME_SERVER_IPV4"
:local sourcePort 13255
:local listenPort 51821
:local tunnelAddress "10.6.13.2/24"
:local tunnelGateway "10.6.13.1"
:local routingTable "vpn"

:if ($privateKey = "CHANGE_ME_CLIENT_PRIVATE_KEY") do={ :error "Set privateKey first" }
:if ($serverPublicKey = "CHANGE_ME_SERVER_PUBLIC_KEY") do={ :error "Set serverPublicKey first" }
:if ($serverTransportIP = "CHANGE_ME_SERVER_IPV4") do={ :error "Set serverTransportIP first" }

:local appId [/app find where name=$appName]
:if ([:len $appId] = 0) do={ :error ("App not found: " . $appName) }

:local appIP [/app get $appId ip-address]
:local slashPos [:find $appIP "/"]
:if ([:typeof $slashPos] != "nil") do={ :set appIP [:pick $appIP 0 $slashPos] }
:if ([:len $appIP] = 0) do={ :error "App has no IP address; start it first" }

:put ("WireGuard Obfuscator App IP: " . $appIP)

:if ([:len [/routing table find where name=$routingTable]] = 0) do={
    /routing table add name=$routingTable fib=yes
}

:local wgId [/interface wireguard find where name=$wgName]
:if ([:len $wgId] = 0) do={
    /interface wireguard add name=$wgName listen-port=$listenPort mtu=1420 private-key=$privateKey comment="wg-obfuscator-app"
    :set wgId [/interface wireguard find where name=$wgName]
} else={
    /interface wireguard set $wgId listen-port=$listenPort mtu=1420 private-key=$privateKey disabled=no
}

:local addressId [/ip address find where interface=$wgName and comment="wg-obfuscator-app"]
:if ([:len $addressId] = 0) do={
    /ip address add address=$tunnelAddress interface=$wgName comment="wg-obfuscator-app"
} else={
    /ip address set $addressId address=$tunnelAddress disabled=no
}

:local peerId [/interface wireguard peers find where name=$peerName]
:if ([:len $peerId] = 0) do={
    /interface wireguard peers add name=$peerName interface=$wgName public-key=$serverPublicKey endpoint-address=$appIP endpoint-port=$sourcePort allowed-address=0.0.0.0/0 persistent-keepalive=25s comment="wg-obfuscator-app"
} else={
    /interface wireguard peers set $peerId interface=$wgName public-key=$serverPublicKey endpoint-address=$appIP endpoint-port=$sourcePort allowed-address=0.0.0.0/0 persistent-keepalive=25s disabled=no
}

:local bypassId [/ip firewall mangle find where comment=$transportBypassComment]
:if ([:len $bypassId] = 0) do={
    /ip firewall mangle add chain=prerouting action=accept src-address=$appIP dst-address=$serverTransportIP comment=$transportBypassComment place-before=0
} else={
    /ip firewall mangle set $bypassId chain=prerouting action=accept src-address=$appIP dst-address=$serverTransportIP disabled=no
    /ip firewall mangle move $bypassId destination=0
}

:local natId [/ip firewall nat find where comment=$clientNatComment]
:if ([:len $natId] = 0) do={
    /ip firewall nat add chain=srcnat action=masquerade out-interface=$wgName comment=$clientNatComment
} else={
    /ip firewall nat set $natId chain=srcnat action=masquerade out-interface=$wgName disabled=no
}

:local routeId [/ip route find where comment=$routeComment]
:local routeGateway ($tunnelGateway . "@main")
:if ([:len $routeId] = 0) do={
    /ip route add dst-address=0.0.0.0/0 gateway=$routeGateway routing-table=$routingTable distance=1 comment=$routeComment
} else={
    /ip route set $routeId dst-address=0.0.0.0/0 gateway=$routeGateway routing-table=$routingTable distance=1 disabled=no
}

:put "Installation complete. Wait a few seconds, then run diagnose.rsc."

