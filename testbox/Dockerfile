FROM ubuntu:bionic

# install apt tools
RUN apt-get update --fix-missing && \
    apt-get install -y apache2-utils curl vim httpie less parallel wget git zip unzip iputils-ping

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

COPY . /appfile

RUN chmod -R 765 /appfile

ENTRYPOINT ["bash"]