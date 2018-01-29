#!/bin/bash

#####################################################
#
# Try and error vlan config tool
#
# Author: solacol
# Version: 0.5
#
#####################################################
#
#
# TODO:
#	- process of checking is exiting to "fast" ...
#	  e.g. maybe vlan id already configured is not the one which is used in the end
#     ... maybe using some kind of interactive mode would be cool
#
# CHANGELOG:
#	- done msg shit
#
####


# Binaries used
IP="$(/usr/bin/which ip)"
PING="$(/usr/bin/which ping)"
SEQ="$(/usr/bin/which seq)"
GREP="$(/usr/bin/which grep)"
ECHO="$(/usr/bin/which echo)"

# Vlan definition
A_VLANS=($(${SEQ} 1100 1 1112))

# Interface and IP addresses used
INT='eth0'
INT_VLAN_IP='10.42.42.2'
INT_VLAN_IP_MASK='24'
INT_VLAN_GW='10.42.42.1'
INT_VLAN_GW_MASK='24'
INT_VLAN_ROUTE='10.0.0.0/8'

# Check if script is running as root
if [ "${EUID}" -ne 0 ]
  then ${ECHO} "Failure: Please run as root"
  exit 1
fi

# Check if interface is existent
CHECK_INT="$(${IP} link show ${INT} 2>&1 | ${GREP} -c 'does not exist')"

if [[ ${CHECK_INT} == 1 ]]; then
	${ECHO} "Failure: Interface ${INT} seems not to be existent"
	exit 1
else
	CHECK_INT_VLAN_IP="$(${IP} a | ${GREP} -c "inet ${INT_VLAN_IP}")"

	# Check if IP is somewhere existent already
	if [[ ${CHECK_INT_VLAN_IP} == 0 ]]; then
        # Check if one of the vlans (with same name or vlan id) is already configured
        for vlan in ${A_VLANS[@]}
        do
                CHECK_INT_VLAN="$(${IP} link show ${INT}.vlan${vlan} 2>&1 | ${GREP} -c 'does not exist')"

                if [[ ${CHECK_INT_VLAN} == 1 ]]; then
	                CHECK_INT_VLAN_ID="$(${IP} -d link | ${GREP} -c "vlan protocol 802.1Q id ${vlan}")"

					if [[ ${CHECK_INT_VLAN_ID} == 0 ]]; then
		                continue
					else
		                ${ECHO} "Failure: Vlan id seems to be configured somewhere already ... exiting"
						exit 1
					fi
                else
                    ${ECHO} "Failure: Vlan interface with this name is already existent ... exiting"
					exit 1
                fi
        done

		# Try and error for each vlan, if gateway can be pinged successfully, use it
		for vlan in ${A_VLANS[@]}
		do
			${IP} link add link ${INT} name ${INT}.vlan${vlan} type vlan id ${vlan}
			${IP} link set dev ${INT}.vlan${vlan} up
			${IP} a a ${INT_VLAN_IP}/${INT_VLAN_IP_MASK} dev ${INT}.vlan${vlan}
			${IP} r a ${INT_VLAN_ROUTE} via ${INT_VLAN_GW} dev ${INT}.vlan${vlan}

			CHECK_PING="$(${PING} -c1 -w1 ${INT_VLAN_GW} | ${GREP} -c '64 bytes from')"

			if [[ ${CHECK_PING} == 1 ]]; then
				${ECHO} "VLAN ${vlan} configured successfully!"
				break
			else
				${ECHO} "Failure: Gateway is not reachable, seems to be the wrong vlan ..."
          		${IP} r d ${INT_VLAN_ROUTE} via ${INT_VLAN_GW} dev ${INT}.vlan${vlan}
                ${IP} link del ${INT}.vlan${vlan}
			fi
		done
	else
		${ECHO} "Failure: ${INT_VLAN_IP} seems to be existent already"
		exit 1
	fi
fi

exit 0
