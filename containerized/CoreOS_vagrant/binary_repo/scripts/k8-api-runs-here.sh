#!/bin/sh

MACHINE_ID=`cat /etc/machine-id`
MACHINE_IP=`fleetctl list-machines -l | grep $MACHINE_ID | cut -f2`

etcdctl set /mycluster/kube/api-server $MACHINE_IP
