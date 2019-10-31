FROM rocker/r-base

# Force the correct number of CPUs
RUN mkdir -p /usr/local/lib/R/etc
ARG NCPUS=1
RUN echo "options(Ncpus = ${NCPUS})" >> "/usr/local/lib/R/etc/Rprofile.site"

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
    pandoc-citeproc
RUN mkdir /build
RUN Rscript -e "install.packages('devtools')"
COPY DESCRIPTION /build
RUN cd /build && Rscript -e "install.packages('devtools'); devtools::install_dev_deps()"

