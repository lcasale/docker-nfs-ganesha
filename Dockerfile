FROM fedora:36
LABEL org.opencontainers.image.authors=marc@slintes.net

# Install dependencies
RUN yum -y install \
    nfs-ganesha nfs-ganesha-vfs \
    nfs-utils rpcbind && \
    # Clean cache
    yum -y clean all

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
# ENTRYPOINT ["/tini", "--"]

COPY rootfs /

VOLUME ["/data/nfs"]

# NFS ports
EXPOSE 111 111/udp 662 2049 38465-38467

ENTRYPOINT ["/tini", "--"]
CMD ["/opt/start_nfs.sh"]