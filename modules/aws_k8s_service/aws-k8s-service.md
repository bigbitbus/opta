---
title: "k8s-service"
linkTitle: "k8s-service"
date: 2021-07-21
draft: false
weight: 1
description: Deploys a kubernetes app
---

The most important module for deploying apps, k8s-service deploys a kubernetes app.
It deploys your service as a rolling update securely and with simple autoscaling right off the bat-- you
can even expose it to the world, complete with load balancing both internally and externally.

## Features

### External/Internal Image

This module supports deploying from an "external" image repository (currently only public ones supported)
by setting the `image` field to the repo (e.g. "kennethreitz/httpbin" in the examples). If you set the value to "AUTO" however,
it will automatically create a secure container repository with ECR on your account. You can then use the `Opta push`
command to push to it!

### Healthcheck Probe

One of the benefits of K8s is that it comes with built-in checks for the responsiveness of your server. These are called
[_liveness_ and _readiness_ probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/).

tl;dr An (optional) liveness probe determines whether your server should be restarted, and an (optional) readiness probe determines if traffic should
be sent to a replica or be temporarily rerouted to other replicas. Essentially smart healthchecks. For websockets Opta
just checks the tcp connection on the given port.

### Autoscaling

As mentioned, autoscaling is available out of the box. We currently only support autoscaling
based on the pod's cpu and memory usage, but we hope to soon offer the ability to use 3rd party metrics like datadog
to scale. As mentioned in the k8s docs, the horizontal pod autoscaler (which is what we use) assumes a linear relationship between # of replicas
and cpu (twice the replicas means half expected cpu usage), which works well assuming low overhead.
The autoscaler then uses this logic to try and balance the cpu/memory usage at the percentage of request. So, for example,
if the target memory is 80% and we requested 100mb, then it'll try to keep the memory usage at 80mb. If it finds that
the average memory usage was 160mb, it would logically try to double the number of replicas.

### Container Resources

One of the other benefits of kubernetes is that a user can have fine control over the [resources used by each of their containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).
A user can control the cpu, memory and disk usage with which scheduling is made, and the max limit after which the container is killed.
With Opta, we expose such settings to the user, while keeping sensible defaults.

_NOTE_ We expose the resource requests and set the limits to twice the request values.

### Ingress

You can control if and how you want to expose your app to the world! Check out
the [Ingress](/features/dns) docs for more details.

### Persistent Storage
A user can now specify persistent storage to be provisioned for your servers and kept intact over your different
deployments + scaling. This will take form of a list of entries holding a `size` (size of the storage to create in 
gigabytes) and `path` (path to put it on your server's container) field, like so:
```yaml
.
.
.
modules:
  - name: app
    type: k8s-service
    image: kennethreitz/httpbin
    min_containers: 2
    max_containers: "{vars.max_containers}"
    liveness_probe_path: "/get"
    readiness_probe_path: "/get"
    port:
      http: 80
    public_uri: "subdomain1.{parent.domain}"
    persistent_storage:
      - path: "/DESIRED/PATH1"
        size: 20 # 20 GB
      - path: "/DESIRED/PATH2"
        size: 30 # 30 GB
.
.
.
```
Under the hood, an AWS EBS volume is being created to house your data for each coexisting server container of your app.

_WARNING_ Switching between having the persistent_storage field set or not will lead to some minor downtime as the
underlying resource kind is being switched.

_NOTE_ because of the nature of these volumes, they will not be cleaned up automatically unless during a service 
destruction. If you wish to release the EBS volumes for whatever reason you will need to manually do so by deleting
the kubernetes persistent volume claims.

### Tolerations

Opta gives you the option of adding [taints](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
to the nodes created in this nodepool, and thusly the ability to add _tolerations_ for said taints. The official 
documentation gives an excellent detailed summary, but in short one can use taints to stop workloads from running in 
said nodes unless they have a matching toleration. Simply provide a list of desired tolerations as inputs like so:
```yaml
  - name: app
    type: k8s-service
    image: AUTO
    healthcheck_path: "/get"
    port:
      http: 80
    tolerations:
      - key: instancetype
        value: memoryoptimized
        effect: "NoExecute"
      - key: team
        value: booking
        # Tolerates for default effect of NoSchedule
      - key: highpriority
        # Tolerates for default value of opta
```

Please refer to the taints specified in your environment Opta manifests to know what matching tolerations are right 
for you.

### Cron Jobs

Opta gives you the option of adding a list of cron jobs to run as part of this service. This is done via the `cron_jobs`
field which a user can fill with entries for each con job in mind. Each entry must specify a command in array format
(for most cases simply specify the shell you wish to use, the `-c` flag and the executable to run), as well as a
schedule following the [Cron Syntax](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#cron-schedule-syntax).
The cron jobs will use the same resource requests/limits as the servers.

For example, here is a service which has a cron job that runs every minute and simply outputs "Hello world!" to stdout:

```yaml
  - name: app
    type: k8s-service
    image: AUTO
    healthcheck_path: "/get"
    port:
      http: 80
    cron_jobs:
      - commands:
        - /bin/sh
        - -c
        - 'echo "Hello world!"'
        schedule: "* * * * *"
```

{{% alert title="Pure Cron Jobs" color="info" %}}
If a user wishes to just have a cron job and no service, then they could simply set the min/max containers to
0.
{{% /alert %}}

{{% alert title="Warning" color="warning" %}}
Cron Jobs are currently created outside the default linkerd service mesh.
{{% /alert %}}