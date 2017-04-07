# Using Docker Build

GitLab CI allows you to use Docker Engine to build and test docker-based projects.

**This also allows to you to use `docker-compose` and other docker-enabled tools.**

One of the new trends in Continuous Integration/Deployment is to:

1. create an application image,
1. run tests against the created image,
1. push image to a remote registry, and
1. deploy to a server from the pushed image.

It's also useful when your application already has the `Dockerfile` that can be used to create and test an image:

```bash
$ docker build -t my-image dockerfiles/
$ docker run my-docker-image /script/to/run/tests
$ docker tag my-image my-registry:5000/my-image
$ docker push my-registry:5000/my-image
```

This requires special configuration of GitLab Runner to enable `docker` support during jobs.

## Runner Configuration

There are three methods to enable the use of `docker build` and `docker run` during jobs; each with their own tradeoffs.

### Use shell executor

The simplest approach is to install GitLab Runner in `shell` execution mode.
GitLab Runner then executes job scripts as the `gitlab-runner` user.

1. Install [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-ci-multi-runner/#installation).

1. During GitLab Runner installation select `shell` as method of executing job scripts or use command:

    ```bash
    sudo gitlab-ci-multi-runner register -n \
      --url https://gitlab.com/ci \
      --registration-token REGISTRATION_TOKEN \
      --executor shell \
      --description "My Runner"
    ```

2. Install Docker Engine on server.

    For more information how to install Docker Engine on different systems
    checkout the [Supported installations](https://docs.docker.com/engine/installation/).

3. Add `gitlab-runner` user to `docker` group:

    ```bash
    sudo usermod -aG docker gitlab-runner
    ```

4. Verify that `gitlab-runner` has access to Docker:

    ```bash
    sudo -u gitlab-runner -H docker info
    ```

    You can now verify that everything works by adding `docker info` to `.gitlab-ci.yml`:

    ```yaml
    before_script:
      - docker info

    build_image:
      script:
        - docker build -t my-docker-image .
        - docker run my-docker-image /script/to/run/tests
    ```

5. You can now use `docker` command and install `docker-compose` if needed.

> **Note:**
* By adding `gitlab-runner` to the `docker` group you are effectively granting `gitlab-runner` full root permissions.
For more information please read [On Docker security: `docker` group considered harmful](https://www.andreas-jung.com/contents/on-docker-security-docker-group-considered-harmful).

### Use docker-in-docker executor

The second approach is to use the special docker-in-docker (dind)
[Docker image](https://hub.docker.com/_/docker/) with all tools installed
(`docker` and `docker-compose`) and run the job script in context of that
image in privileged mode.

In order to do that, follow the steps:

1. Install [GitLab Runner](https://docs.gitlab.com/runner/install).

1. Register GitLab Runner from the command line to use `docker` and `privileged`
   mode:

    ```bash
    sudo gitlab-ci-multi-runner register -n \
      --url https://gitlab.com/ci \
      --registration-token REGISTRATION_TOKEN \
      --executor docker \
      --description "My Docker Runner" \
      --docker-image "docker:latest" \
      --docker-privileged
    ```

    The above command will register a new Runner to use the special
    `docker:latest` image which is provided by Docker. **Notice that it's using
    the `privileged` mode to start the build and service containers.** If you
    want to use [docker-in-docker] mode, you always have to use `privileged = true`
    in your Docker containers.

    The above command will create a `config.toml` entry similar to this:

    ```
    [[runners]]
      url = "https://gitlab.com/ci"
      token = TOKEN
      executor = "docker"
      [runners.docker]
        tls_verify = false
        image = "docker:latest"
        privileged = true
        disable_cache = false
        volumes = ["/cache"]
      [runners.cache]
        Insecure = false
    ```

1. You can now use `docker` in the build script (note the inclusion of the
   `docker:dind` service):

    ```yaml
    image: docker:latest

    # When using dind, it's wise to use the overlayfs driver for
    # improved performance.
    variables:
      DOCKER_DRIVER: overlay

    services:
    - docker:dind

    before_script:
    - docker info

    build:
      stage: build
      script:
      - docker build -t my-docker-image .
      - docker run my-docker-image /script/to/run/tests
    ```

Docker-in-Docker works well, and is the recommended configuration, but it is
not without its own challenges:

- By enabling `--docker-privileged`, you are effectively disabling all of
  the security mechanisms of containers and exposing your host to privilege
  escalation which can lead to container breakout. For more information, check
  out the official Docker documentation on
  [Runtime privilege and Linux capabilities][docker-cap].
- When using docker-in-docker, each job is in a clean environment without the past
  history. Concurrent jobs work fine because every build gets it's own
  instance of Docker engine so they won't conflict with each other. But this
  also means jobs can be slower because there's no caching of layers.
- By default, `docker:dind` uses `--storage-driver vfs` which is the slowest
  form offered. To use a different driver, see
  [Using the overlayfs driver](#using-the-overlayfs-driver).

An example project using this approach can be found here: https://gitlab.com/gitlab-examples/docker.

### Use Docker socket binding

The third approach is to bind-mount `/var/run/docker.sock` into the container so that docker is available in the context of that image.

In order to do that, follow the steps:

1. Install [GitLab Runner](https://docs.gitlab.com/runner/install).

1. Register GitLab Runner from the command line to use `docker` and share `/var/run/docker.sock`:

    ```bash
    sudo gitlab-ci-multi-runner register -n \
      --url https://gitlab.com/ci \
      --registration-token REGISTRATION_TOKEN \
      --executor docker \
      --description "My Docker Runner" \
      --docker-image "docker:latest" \
      --docker-volumes /var/run/docker.sock:/var/run/docker.sock
    ```

    The above command will register a new Runner to use the special
    `docker:latest` image which is provided by Docker. **Notice that it's using
    the Docker daemon of the Runner itself, and any containers spawned by docker
    commands will be siblings of the Runner rather than children of the runner.**
    This may have complications and limitations that are unsuitable for your workflow.

    The above command will create a `config.toml` entry similar to this:

    ```
    [[runners]]
      url = "https://gitlab.com/ci"
      token = REGISTRATION_TOKEN
      executor = "docker"
      [runners.docker]
        tls_verify = false
        image = "docker:latest"
        privileged = false
        disable_cache = false
        volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
      [runners.cache]
        Insecure = false
    ```

1. You can now use `docker` in the build script (note that you don't need to
   include the `docker:dind` service as when using the Docker in Docker executor):

    ```yaml
    image: docker:latest

    before_script:
    - docker info

    build:
      stage: build
      script:
      - docker build -t my-docker-image .
      - docker run my-docker-image /script/to/run/tests
    ```

While the above method avoids using Docker in privileged mode, you should be
aware of the following implications:

- By sharing the docker daemon, you are effectively disabling all
  the security mechanisms of containers and exposing your host to privilege
  escalation which can lead to container breakout. For example, if a project
  ran `docker rm -f $(docker ps -a -q)` it would remove the GitLab Runner
  containers.
- Concurrent jobs may not work; if your tests
  create containers with specific names, they may conflict with each other.
- Sharing files and directories from the source repo into containers may not
  work as expected since volume mounting is done in the context of the host
  machine, not the build container, e.g.:

    ```
    docker run --rm -t -i -v $(pwd)/src:/home/app/src test-image:latest run_app_tests
    ```

## Using the OverlayFS driver

By default, when using `docker:dind`, Docker uses the `vfs` storage driver which
copies the filesystem on every run. This is a very disk-intensive operation
which can be avoided if a different driver is used, for example `overlay`.

1. Make sure a recent kernel is used, preferably `>= 4.2`.
1. Check whether the `overlay` module is loaded:

    ```
    sudo lsmod | grep overlay
    ```

    If you see no result, then it isn't loaded. To load it use:

    ```
    sudo modprobe overlay
    ```

    If everything went fine, you need to make sure module is loaded on reboot.
    On Ubuntu systems, this is done by editing `/etc/modules`. Just add the
    following line into it:

    ```
    overlay
    ```

1. Use the driver by defining a variable at the top of your `.gitlab-ci.yml`:

    ```
    variables:
      DOCKER_DRIVER: overlay
    ```

## Using the GitLab Container Registry

> **Notes:**
- This feature requires GitLab 8.8 and GitLab Runner 1.2.
- Starting from GitLab 8.12, if you have 2FA enabled in your account, you need
  to pass a personal access token instead of your password in order to login to
  GitLab's Container Registry.

Once you've built a Docker image, you can push it up to the built-in
[GitLab Container Registry](../../user/project/container_registry.md). For example,
if you're using docker-in-docker on your runners, this is how your `.gitlab-ci.yml`
could look like:

```yaml
 build:
   image: docker:latest
   services:
   - docker:dind
   stage: build
   script:
     - docker login -u gitlab-ci-token -p $CI_JOB_TOKEN registry.example.com
     - docker build -t registry.example.com/group/project/image:latest .
     - docker push registry.example.com/group/project/image:latest
```

You have to use the special `gitlab-ci-token` user created for you in order to
push to the Registry connected to your project. Its password is provided in the
`$CI_JOB_TOKEN` variable. This allows you to automate building and deployment
of your Docker images.

You can also make use of [other variables](../variables/README.md) to avoid hardcoding:

```yaml
services:
  - docker:dind

variables:
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_NAME

before_script:
  - docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY

build:
  stage: build
  script:
    - docker build -t $IMAGE_TAG .
    - docker push $IMAGE_TAG
```

Here, `$CI_REGISTRY_IMAGE` would be resolved to the address of the registry tied
to this project, and `$CI_COMMIT_REF_NAME` would be resolved to the branch or
tag name for this particular job. We also declare our own variable, `$IMAGE_TAG`,
combining the two to save us some typing in the `script` section.

Here's a more elaborate example that splits up the tasks into 4 pipeline stages,
including two tests that run in parallel. The `build` is stored in the container
registry and used by subsequent stages, downloading the image
when needed. Changes to `master` also get tagged as `latest` and deployed using
an application-specific deploy script:

```yaml
image: docker:latest
services:
- docker:dind

stages:
- build
- test
- release
- deploy

variables:
  CONTAINER_TEST_IMAGE: registry.example.com/my-group/my-project/my-image:$CI_COMMIT_REF_NAME
  CONTAINER_RELEASE_IMAGE: registry.example.com/my-group/my-project/my-image:latest

before_script:
  - docker login -u gitlab-ci-token -p $CI_JOB_TOKEN registry.example.com

build:
  stage: build
  script:
    - docker build --pull -t $CONTAINER_TEST_IMAGE .
    - docker push $CONTAINER_TEST_IMAGE

test1:
  stage: test
  script:
    - docker pull $CONTAINER_TEST_IMAGE
    - docker run $CONTAINER_TEST_IMAGE /script/to/run/tests

test2:
  stage: test
  script:
    - docker pull $CONTAINER_TEST_IMAGE
    - docker run $CONTAINER_TEST_IMAGE /script/to/run/another/test

release-image:
  stage: release
  script:
    - docker pull $CONTAINER_TEST_IMAGE
    - docker tag $CONTAINER_TEST_IMAGE $CONTAINER_RELEASE_IMAGE
    - docker push $CONTAINER_RELEASE_IMAGE
  only:
    - master

deploy:
  stage: deploy
  script:
    - ./deploy.sh
  only:
    - master
```

Some things you should be aware of when using the Container Registry:

- You must log in to the container registry before running commands. Putting
  this in `before_script` will run it before each job.
- Using `docker build --pull` makes sure that Docker fetches any changes to base
  images before building just in case your cache is stale. It takes slightly
  longer, but means you don’t get stuck without security patches to base images.
- Doing an explicit `docker pull` before each `docker run` makes sure to fetch
  the latest image that was just built. This is especially important if you are
  using multiple runners that cache images locally. Using the git SHA in your
  image tag makes this less necessary since each job will be unique and you
  shouldn't ever have a stale image, but it's still possible if you re-build a
  given commit after a dependency has changed.
- You don't want to build directly to `latest` in case there are multiple jobs
  happening simultaneously.

[docker-in-docker]: https://blog.docker.com/2013/09/docker-can-now-run-within-docker/
[docker-cap]: https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities
