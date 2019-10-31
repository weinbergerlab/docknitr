# docknitr — using Docker to process rmarkdown blocks

## Installation

```r
devtools::install_github("weinbergerlab/docknitr")
```

## Documentation



If you are using Rmarkdown, you may know that it already has the ability to process blocks in languages other than R. For example, a block like this will be processed by Python:

```{python}
print("This is Python in Rmarkdown")
```

You may have also heard about Docker, but if you haven't the brief summary is that it's a tool that lets you create Unix and Windows environments containing software of your choosing. These environments are isolated from each other, which is great for keeping software needed by different projects separate from each other.

For example, if you have one project that requires Python 3.4 on Ubuntu Linux and another that requires Python 3.5 on Windows, you can have both on your computer (regardless of whether your computer is running macOS, Windows, or Unix). This is very similar to virtual machines you can get from Virtual Box, VMware Fusion, or Parallels, but Docker is far superior when it comes to integrating with other tools on your system, which makes it suitable for use inside Rmarkdown.

## Installing Docker

Before you begin, you should definitely install Docker from [the official site](https://www.docker.com/get-started). After you install it, make sure that it is working properly by running the following in your Rstudio terminal:

```
docker run python:3 python -c 'print("Success!")'
```

You should see Docker download Python and then print "Success!":

```
Unable to find image 'python:3' locally
3: Pulling from library/python
c7b7d16361e0: Pull complete
b7a128769df1: Pull complete
1128949d0793: Pull complete
667692510b70: Pull complete
bed4ecf88e6a: Pull complete
8a8c75f3996a: Pull complete
bfbf6161579f: Pull complete
6e3c2947832c: Pull complete
5bab73b08276: Pull complete
Digest: sha256:514a95a32b86cafafefcecc28673bb647d44c5aadf06203d39c43b9c3f61ed52
Status: Downloaded newer image for python:3
Success!
```

If you run the same command again, Docker doesn't need to re-download Python, so it simply prints the output of your command:

```
Success!
```

Either way, you just ran a clean copy of Python 3, regardless of which operating system you are on and which version of Python you already have installed.

Docker's name for a packaged software environment is "Docker image". For example, the thing that got downloaded above when you ran Python in Docker was the Python 3 image. Images have tags of the form of `software:version`; for example, `python:3` is the tag that we used above to tell Docker to download Python version 3. 

Running a docker image creates a Docker container, which is one particular instance of that software. Just as you can have multiple RStudio sessions running at the same time on your computer, you can run multiple Docker containers from the same Docker image. 

## Using Docker in Rmarkdown

Rmarkdown decides what software to use to process a block based on the `{}` tag at the front of a block. This package (`docknitr`), adds Docker to the list of software known to Rmarkdown. After you install `docknitr`, you can — for example — use:

```
{docker, image="python:3"}
print("This is Python in Docker in Rmarkdown")
```

to process an Rmarkdown block using the `python:3` image in Docker.

For the technically inclined, this runs the specified image using `docker run --interactive`, gives it the code block on standard input, and returns its standard output to Rmarkdown output. 

### File access

Normally, Docker containers are isolated from files on your computer, and can't either read them or write them. For example, if you run the `bash` image, the container will see files inside the image, not on your computer:

```
{docker, image="bash:latest"}
ls
```

gives the output

```
bin
dev
etc
home
lib
media
mnt
opt
proc
root
run
sbin
srv
sys
tmp
usr
var
```

To enable file sharing between your computer and Rmarkdown docker blocks, you need to use the `share.files` block option to share the Rstudio working directory (which is normally where your Rmarkdown file is) with the Docker image. For example:

```
{docker, image="bash:latest", share.files=TRUE}
ls
```

produces this on my computer:

```
DESCRIPTION
NAMESPACE
R
README.md
docknitr.Rproj
man
```

For the technically-inclined, this adds a bind-mount of the current working directory to `/workdir` on the Docker container, and sets `/workdir` as the working directory of the container.

### Docker image commands

Whereas some Docker images (such as `python` and `bash`) contain a single piece of software, some others contain multiple tools, and therefore require you to specify which you want to run. A common example are operating system images (such as `ubuntu`). For example, if you want to have access to all the tools built into Ubuntu, and of those you want to run bash, you can use the `command` block option:

```
{docker, image="ubuntu:latest", command="bash", share.files=TRUE}
ls
```

### Shorthands

You will probably find yourself frequently using the same Docker images and commands over and over again. To make your life easier, you can create an alias, so that instead of writing

```
{docker, image="ubuntu:latest", command="bash", share.files=TRUE}
ls
```

you can simply write

```
{docker-bash}
ls
```

This is accomplished using `docknitr::alias`. First add this to an R block in yoru Rmarkdown:

```
docknitr::alias("docker-bash"=list(image="ubuntu:latest", command="bash", share.files=TRUE))
```

and then you can use `docker-bash` as shorthand for bash in Ubuntu in Docker:

```{docker-bash}
ls
```

### Making custom images

One of Docker's superpowers is the ability to easily make custom images. The full range of capabilities of custom Docker images is far beyond the scope of this documentation, but the short version is that to make a custom image you need to take two steps: first, you create a file ("Dockerfile") that contains instructions for how to build a custom image based on an existing image. 

For example, if you wanted to have a custom image in which you have Python 3 with some Python packages preinstalled, you might create a Docker file as follows:

```
FROM python:3

RUN pip install munch
```

This file should live in a folder by itself; let's call that folder `python3+munch`.

The second step is to build and tag this custom image using a Terminal command like this one:

```
docker build --tag python3+munch python3+munch
```

The first parameter is the tag you want to give your custom image, and the second is the name of the folder containing the Dockerfile. In our case, both are `python3+munch`.

Having done so, you can use your tagged custom image from Rmarkdown:

```{docker image="python3+munch"}
import munch
```

