#!/bin/bash
set -xeuo pipefail
# Pull the latest FCOS build, unpack its container image, and verify
# that we can re-encapsulate it as chunked.

ver=37.20230126.20.0
container=quay.io/fedora/fedora-coreos:${ver}

tmpdir=/tmp/coreTest-${ver}
mkdir -p ${tmpdir}
cd ${tmpdir}
ostree --repo=repo init
cat /etc/ostree/remotes.d/fedora.conf >> repo/config

# Pull and unpack the ostree content, discarding the container wrapping
ostree container unencapsulate --write-ref=testref --repo=repo ostree-unverified-image:containers-storage:${container}

# Re-pack it as a (chunked) container
start=`date +%s.%N`
/home/redhat/work/dev-updates-remoting/rpm-ostree/rpm-ostree compose container-encapsulate --repo=repo testref oci:${tmpdir}/test.oci
end=`date +%s.%N`
runtime=$( echo "$end - $start" | bc -l )
skopeo inspect oci:${tmpdir}/test.oci | jq '.LayersData | .[0].Annotations.Content' > annotation_ostree.txt
grep -qFe ostree_commit annotation_ostree.txt
skopeo inspect --config oci:${tmpdir}/test.oci | jq '.rootfs.diff_ids' > layersDiffids.txt
echo ok
