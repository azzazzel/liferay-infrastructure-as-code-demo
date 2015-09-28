= Start Kubernetes with cloundinit =

Starting Kubernetes as Fleet units has one important benefit: fleet will make sure:
  - Kubernetes master is always running (on some of the `manager` nodes)
  - All `worker` nodes will automatically have `kubelet` and `proxy` runnig
  - All `frontend` nodes will automatically have `proxy` runnig

The fleet units for the 5 Kubernetes services are in `provisioning/fleet-unis`. 
For the purpos of this demo they are installed manually using `fleetctl` from the machine hosting the demo.
However the process can be automated. Those files can be coopied to the server (say in `/etc/fleet-units/`) during server provisioning.
Then a `systemd` service configured via `cloudinit` for each `manager` node, could make sure they are started:

```yml   
    - name: fleet-units.service
      command: start
      content: |
        [Unit]
        Description=Start all fleet units from /etc/fleet-units  
        After=fleet.service
        Requires=fleet.service

        [Service]
        ExecStartPre=/bin/sh -c "timeout 10s fleetctl load `find /etc/fleet-units/* | tr '\n' ' '` || true"
        ExecStart=/bin/sh -c "fleetctl start `find /etc/fleet-units/* | tr '\n' ' '`"
```

Essentially what this does is calling `fleetctl` to load all units described in `/etc/fleet-units/` folder. As each unit there has it's own policy on which machine it should run, it doesn't really matter from which machine this service will be started. To play it safe (see known issues below) we have this on each `manager` node!  


==== Known issues ====

Fleet needs to store the units in Etcd. When there is Etcd cluster with more then 1 node, Etcd will become available only after more than half of the nodes in cluster become available. For example in case if 3 `manager` nodes, Etcd will become available after the first two are up and runnig. Thus an attempt to start Fleet units on the first node will fail. However the same attempt on the second node will succeed. Having Fleet trying to start units from `/etc/fleet-units/` folder on every `manager` machine guarantees that at least one attempt will succeed (as soon as Etcd becomes available) no matter in what order `manager` nodes are started.           

For some reason `fleet start <some_unit_file>` freezes on some unit files (perhaps because of this issue https://github.com/coreos/fleet/issues/1331). 
The units are still submitted OK but it seams the process is still waiting for something and it does not start them. To work around this issue the configuration above uses two commands. First it executes:

```
/bin/sh -c "timeout 10s fleetctl load `find /etc/fleet-units/* | tr '\n' ' '` || true"
```

which gives the `fleetctl` 10 seconds to finish and kills it after that __(`|| true` prevents `systemd` from giving up because of the error code `timeout` may return.)__Then we call it one more time:

```
/bin/sh -c "fleetctl start `find /etc/fleet-units/* | tr '\n' ' '`"
```
to actually start the services.
