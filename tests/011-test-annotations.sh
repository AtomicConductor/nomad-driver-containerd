#!/bin/bash

source $SRCDIR/utils.sh

test_annotations_nomad_job() {
    pushd ~/go/src/github.com/Roblox/nomad-driver-containerd/example

    echo "INFO: Starting nomad annotations job using nomad-driver-containerd."
    nomad job run -detach annotations.nomad

    annotations_status=$(nomad job status -short annotations|grep Status|awk '{split($0,a,"="); print a[2]}'|tr -d ' ')
    if [ annotations_status != "running" ];then
        echo "ERROR: Error in getting annotations job status."
        exit 1
    fi

    # Even though $(nomad job status) reports annotations job status as "running"
    # The actual container process might not be running yet.
    # We need to wait for actual container to start running before trying exec.
    echo "INFO: Wait for annotations container to get into RUNNING state, before trying exec."
    is_container_active annotations false

    echo "INFO: Check annotations are found when inspecting container"
    export CONTAINERD_NAMESPACE=nomad; ctr containers ls| grep annotations | cut -d ' ' -f1 | xargs ctr containers info | jq '.Spec.annotations.test' | tr -d '"' | xargs -I % test % = "annotations"
    if [ $? != 0 ]; then
        echo "ERROR: Error in finding annotations."
        exit 1
    fi

    echo "INFO: Stopping nomad annotations job."
    nomad job stop -detach annotations
    annotations_status=$(nomad job status -short annotations|grep Status|awk '{split($0,a,"="); print a[2]}'|tr -d ' ')
    if [ $annotations_status != "dead(stopped)" ];then
        echo "ERROR: Error in stopping annotations job."
        exit 1
    fi

    echo "INFO: purge nomad annotations job."
    nomad job stop -detach -purge annotations
    popd
}

test_annotations_nomad_job
