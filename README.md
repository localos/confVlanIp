# confVlanIp
Simple script for auto-config VLAN, IP etc. based on a successful ping to the corresponding gateway.

Script can be used to configure given VLANs, IPs etc. on multiple systems in a "easy" (NOT failssafe) way (via systemd or networkmanager if-up/down scripts). Gateway has to be pingable.

First VLAN/IP combination that results in a successful ping will be used.
