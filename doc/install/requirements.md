# Requirements

## Operating Systems

### Supported Unix distributions

- Ubuntu
- Debian
- CentOS
- Red Hat Enterprise Linux (please use the CentOS packages and instructions)
- Scientific Linux (please use the CentOS packages and instructions)
- Oracle Linux (please use the CentOS packages and instructions)

For the installations options please see [the installation page on the GitLab website](https://about.gitlab.com/installation/).

### Unsupported Unix distributions

- Arch Linux
- Fedora
- FreeBSD
- Gentoo
- macOS

On the above unsupported distributions is still possible to install GitLab yourself.
Please see the [installation from source guide](installation.md) and the [installation guides](https://about.gitlab.com/installation/) for more information.

### Non-Unix operating systems such as Windows

GitLab is developed for Unix operating systems.
GitLab does **not** run on Windows and we have no plans of supporting it in the near future.
Please consider using a virtual machine to run GitLab.

## Ruby versions

GitLab requires Ruby (MRI) 2.3. Support for Ruby versions below 2.3 (2.1, 2.2) will stop with GitLab 8.13.

You will have to use the standard MRI implementation of Ruby.
We love [JRuby](http://jruby.org/) and [Rubinius](http://rubini.us/) but GitLab
needs several Gems that have native extensions.

## Hardware requirements

### Storage

The necessary hard drive space largely depends on the size of the repos you want to store in GitLab but as a *rule of thumb* you should have at least as much free space as all your repos combined take up.

If you want to be flexible about growing your hard drive space in the future consider mounting it using LVM so you can add more hard drives when you need them.

Apart from a local hard drive you can also mount a volume that supports the network file system (NFS) protocol. This volume might be located on a file server, a network attached storage (NAS) device, a storage area network (SAN) or on an Amazon Web Services (AWS) Elastic Block Store (EBS) volume.

If you have enough RAM memory and a recent CPU the speed of GitLab is mainly limited by hard drive seek times. Having a fast drive (7200 RPM and up) or a solid state drive (SSD) will improve the responsiveness of GitLab.

### CPU

- 1 core supports up to 100 users but the application can be a bit slower due to having all workers and background jobs running on the same core
- **2 cores** is the **recommended** number of cores and supports up to 500 users
- 4 cores supports up to 2,000 users
- 8 cores supports up to 5,000 users
- 16 cores supports up to 10,000 users
- 32 cores supports up to 20,000 users
- 64 cores supports up to 40,000 users
- More users? Run it on [multiple application servers](https://about.gitlab.com/high-availability/)

### Memory

You need at least 4GB of addressable memory (RAM + swap) to install and use GitLab!
The operating system and any other running applications will also be using memory
so keep in mind that you need at least 4GB available before running GitLab. With
less memory GitLab will give strange errors during the reconfigure run and 500
errors during usage.

- 1GB RAM + 3GB of swap is the absolute minimum but we strongly **advise against** this amount of memory. See the unicorn worker section below for more advice.
- 2GB RAM + 2GB swap supports up to 100 users but it will be very slow
- **4GB RAM** is the **recommended** memory size for all installations and supports up to 100 users
- 8GB RAM supports up to 1,000 users
- 16GB RAM supports up to 2,000 users
- 32GB RAM supports up to 4,000 users
- 64GB RAM supports up to 8,000 users
- 128GB RAM supports up to 16,000 users
- 256GB RAM supports up to 32,000 users
- More users? Run it on [multiple application servers](https://about.gitlab.com/high-availability/)

We recommend having at least 2GB of swap on your server, even if you currently have
enough available RAM. Having swap will help reduce the chance of errors occurring
if your available memory changes.

Notice: The 25 workers of Sidekiq will show up as separate processes in your process overview (such as top or htop) but they share the same RAM allocation since Sidekiq is a multithreaded application. Please see the section below about Unicorn workers for information about many you need of those.

## GitLab Runner

We strongly advise against installing GitLab Runner on the same machine you plan
to install GitLab on. Depending on how you decide to configure GitLab Runner and
what tools you use to exercise your application in the CI environment, GitLab
Runner can consume significant amount of available memory.

Memory consumption calculations, that are available above, will not be valid if
you decide to run GitLab Runner and the GitLab Rails application on the same
machine.

It is also not safe to install everything on a single machine, because of the
[security reasons] - especially when you plan to use shell executor with GitLab
Runner.

We recommend using a separate machine for each GitLab Runner, if you plan to
use the CI features.

[security reasons]: https://gitlab.com/gitlab-org/gitlab-ci-multi-runner/blob/master/docs/security/index.md

## Unicorn Workers

It's possible to increase the amount of unicorn workers and this will usually help to reduce the response time of the applications and increase the ability to handle parallel requests.

For most instances we recommend using: CPU cores + 1 = unicorn workers.
So for a machine with 2 cores, 3 unicorn workers is ideal.

For all machines that have 2GB and up we recommend a minimum of three unicorn workers.
If you have a 1GB machine we recommend to configure only two Unicorn workers to prevent excessive swapping.

To change the Unicorn workers when you have the Omnibus package please see [the Unicorn settings in the Omnibus GitLab documentation](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/unicorn.md#unicorn-settings).

## Database

We currently support the following databases:

- PostgreSQL (recommended)
- MySQL/MariaDB

If you want to run the database separately, expect a size of about 1 MB per user.

### PostgreSQL Requirements

As of GitLab 9.0, PostgreSQL 9.6 is recommended. Lower versions of PostgreSQL
may work but primary testing and developement takes place using PostgreSQL 9.6.

Users using PostgreSQL must ensure the `pg_trgm` extension is loaded into every
GitLab database. This extension can be enabled (using a PostgreSQL super user)
by running the following query for every database:

```
CREATE EXTENSION pg_trgm;
```

On some systems you may need to install an additional package (e.g.
`postgresql-contrib`) for this extension to become available.

## Redis and Sidekiq

Redis stores all user sessions and the background task queue.
The storage requirements for Redis are minimal, about 25kB per user.
Sidekiq processes the background jobs with a multithreaded process.
This process starts with the entire Rails stack (200MB+) but it can grow over time due to memory leaks.
On a very active server (10,000 active users) the Sidekiq process can use 1GB+ of memory.

## Prometheus and its exporters

As of Omnibus GitLab 9.0, [Prometheus](https://prometheus.io) and its related
exporters are enabled by default, to enable easy and in depth monitoring of
GitLab. Approximately 200MB of memory will be consumed by these processes, with
default settings.

If you would like to disable Prometheus and it's exporters or read more information
about it, check the [Prometheus documentation](../administration/monitoring/prometheus/index.md).

## Supported web browsers

We support the current and the previous major release of Firefox, Chrome/Chromium, Safari and Microsoft browsers (Microsoft Edge and Internet Explorer 11).

Each time a new browser version is released, we begin supporting that version and stop supporting the third most recent version.