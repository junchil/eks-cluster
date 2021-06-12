FROM ubuntu:bionic

# install apt tools
RUN apt-get update --fix-missing && \
    apt-get install -y apache2-utils curl vim httpie less parallel wget git

ENTRYPOINT ["bash"]