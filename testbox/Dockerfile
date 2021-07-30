FROM ubuntu:bionic

# install apt tools
RUN apt-get update --fix-missing && \
    apt-get install -y apache2-utils curl vim httpie less parallel wget git zip unzip

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install
 
ENTRYPOINT ["bash"]