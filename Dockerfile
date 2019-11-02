FROM rocker/r-base

# Install docker cli
RUN apt-get update && apt-get install --yes --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    gnupg-agent \
    software-properties-common
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable"
RUN apt-get update && apt-get install --yes --no-install-recommends docker-ce-cli

# Install development deps
RUN apt-get update && \
  apt-get install --yes --no-install-recommends \
    file \
    libcurl4-openssl-dev \
    libgit2-dev \
    libssl-dev \
    libssh2-1-dev \
    libxml2-dev \
    pandoc \
    pandoc-citeproc \
    qpdf
RUN mkdir /build
RUN Rscript -e "install.packages('devtools')"
COPY DESCRIPTION /build
RUN cd /build && Rscript -e "devtools::install_dev_deps()"

