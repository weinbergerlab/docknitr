FROM ubuntu:19.04
RUN apt-get update --quiet && apt-get install --quiet --yes --no-install-recommends \
  wget \
  python3-setuptools \
  python3-wheel \
  python3-pip \
  python3-numpy \
  python3-scipy \
  python3-statsmodels \
  python3-pysam \
  python3-pybedtools \
  mash
RUN pip3 install pyseer
