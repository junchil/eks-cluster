#Run Stage
FROM ubuntu:bionic

# copy binaries
COPY ./godbweb .
RUN chmod +x godbweb

# copy configure
COPY conf.toml .

# copy assets
COPY assets /assets

EXPOSE 3000

ENTRYPOINT ["bash"]