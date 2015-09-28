
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [[ ":$PATH:" != *":$DIR:"* ]]; then
       export PATH=$PATH:$DIR
fi

export FLEETCTL_ENDPOINT=http://192.168.10.101:4001
export ETCDCTL_PEERS=http://192.168.10.101:4001
