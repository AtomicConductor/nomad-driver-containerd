# nomad-driver-containerd
Nomad task driver for launching containers using containerd.

**Containerd** [`(containerd.io)`](https://containerd.io) is a lightweight container daemon for
running and managing container lifecycle.<br/>
Docker daemon also uses containerd.

```
dockerd (docker daemon) --> containerd --> containerd-shim --> runc
```

**nomad-driver-containerd** enables nomad client to launch containers directly using containerd, without docker!<br/>
Docker daemon is not required on the host system.

## nomad-driver-containerd architecture
<img src="images/nomad_driver_containerd.png" width="850" height="475" />

## Requirements

- [Nomad](https://www.nomadproject.io/downloads.html) >=v0.11
- [Go](https://golang.org/doc/install) >=v1.11
- [Containerd](https://containerd.io/downloads/) >=1.3

## Installing containerd

Containerd can be build from the [`source`](https://github.com/containerd/containerd) OR
pre-compiled binary can be downloaded from [`here`](https://containerd.io/downloads/)

```
$ cd /tmp
$ curl -L -o containerd-1.3.4.linux-amd64.tar.gz https://github.com/containerd/containerd/releases/download/v1.3.4/containerd-1.3.4.linux-amd64.tar.gz
$ sudo tar -C /usr/local -xzf containerd-1.3.4.linux-amd64.tar.gz
$ rm -f containerd-1.3.4.linux-amd64.tar.gz
```
Once containerd is installed in `/usr/local/bin`, it can be managed using process supervisors or init systems like systemd. An example systemd unit file looks something like this.
```
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd
KillMode=process
Delegate=yes
LimitNOFILE=1048576
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity

[Install]
WantedBy=multi-user.target
```
Once the systemd unit is dropped in `/lib/systemd/system/containerd.service`, you can start containerd:
```
$ sudo systemctl daemon-reload
$ sudo systemctl start containerd
$ sudo systemctl status containerd
```
## Building nomad-driver-containerd
```
$ mkdir -p $GOPATH/src/github.com/Roblox
$ cd $GOPATH/src/github.com/Roblox
$ git clone git@github.com:Roblox/nomad-driver-containerd.git
$ cd nomad-driver-containerd
$ make build (This will build your containerd-driver binary)
```

### Start a nomad dev server with nomad-driver-containerd task driver

```
$ mkdir -p /tmp/nomad-driver-containerd
$ cd /tmp/nomad-driver-containerd
$ ln -s $GOPATH/src/github.com/Roblox/nomad-driver-containerd/containerd-driver containerd-driver
$ cd $GOPATH/src/github.com/Roblox/nomad-driver-containerd/example
$ nomad agent -dev -config=agent.hcl -plugin-dir=/tmp/nomad-driver-containerd
```

Once the nomad server is up and running, you can check the registered task drivers (which will also show `nomad-driver-containerd`) using:

```
$ nomad node status <nodeid>
```

## Run Example jobs.

There are few example jobs in the [`example`](https://github.com/Roblox/nomad-driver-containerd/tree/readme/example) directory.

```
$ nomad job run <job_name.nomad>
```
will launch the job, as long as both nomad server (+nomad-driver-containerd) and containerd are running on your system.
More detailed instructions are in the [`example README.md`](https://github.com/Roblox/nomad-driver-containerd/tree/readme/example)

## Tests
```
$ make test
```
**NOTE**: These are destructive tests and can leave the system in a changed state.<br/>
It is highly recommended to run these tests either as part of a CI/CD system or on
a immutable infrastructure e.g VMs.

## Cleanup
```
make clean
``` 
This will delete your binary: containerd-driver.
