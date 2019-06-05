FROM fedora:29
MAINTAINER marc@slintes.net

# Install dependencies
RUN yum -y install \
    nfs-ganesha nfs-ganesha-vfs \
    nfs-utils rpcbind && \
    # Clean cache
    yum -y clean all

# Add Tini
ENV TINI_VERSION v0.16.1
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc /tini.asc
RUN set -x \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg2 --keyserver ha.pool.sks-keyservers.net --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
    && gpg2 --verify /tini.asc \
    && rm -rf "$GNUPGHOME" /tini.asc \
    && chmod +x /tini

COPY rootfs /

VOLUME ["/data/nfs"]

# NFS ports
EXPOSE 111 111/udp 662 2049 38465-38467

ENTRYPOINT ["/tini", "--"]
CMD ["/opt/start_nfs.sh"]