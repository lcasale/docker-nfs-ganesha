#!/bin/bash

set -e

# environment variables

: ${EXPORT_PATH:="/data/nfs"}
: ${PSEUDO_PATH:="/"}
: ${EXPORT_ID:=0}
: ${PROTOCOLS:=4}
: ${TRANSPORTS:="UDP, TCP"}
: ${SEC_TYPE:="sys"}
: ${SQUASH_MODE:="No_Root_Squash"}
: ${GRACELESS:=true}
: ${VERBOSITY:="NIV_EVENT"} # NIV_DEBUG, NIV_EVENT, NIV_WARN

: ${GANESHA_CONFIG:="/etc/ganesha/ganesha.conf"}
: ${GANESHA_LOGFILE:="/dev/stdout"}

init_rpc() {
    echo "* Starting rpcbind"
    if [ ! -x /run/rpcbind ] ; then
        install -m755 -g 32 -o 32 -d /run/rpcbind
    fi
    rpcbind || return 0
    rpc.statd -L || return 0
    rpc.idmapd || return 0
    sleep 1
}

bootstrap_config() {
    echo "* Writing configuration"
    cat <<END >${GANESHA_CONFIG}

NFS_Core_Param{
	MNT_Port = 20048;
	fsid_device = true;
}
NFSV4{
	Grace_Period = 90;
}

EXPORT{
    Export_Id = ${EXPORT_ID};
    Path = "${EXPORT_PATH}";
    Pseudo = "${PSEUDO_PATH}";
    FSAL {
        Name = VFS;
    }
    Access_type = RW;
    Disable_ACL = true;
    Squash = ${SQUASH_MODE};
    Protocols = ${PROTOCOLS};
}

EXPORT_DEFAULTS{
    Transports = ${TRANSPORTS};
    SecType = ${SEC_TYPE};
}

END
}

sleep 0.5

if [ ! -f ${EXPORT_PATH} ]; then
    mkdir -p "${EXPORT_PATH}"
fi

echo "Initializing Ganesha NFS server"
echo "=================================="
echo "export path: ${EXPORT_PATH}"
echo "=================================="

bootstrap_config
init_rpc

echo "Generated NFS-Ganesha config:"
cat ${GANESHA_CONFIG}

echo "* Starting Ganesha-NFS"
exec /usr/bin/ganesha.nfsd -F -L ${GANESHA_LOGFILE} -f ${GANESHA_CONFIG} -N ${VERBOSITY}
