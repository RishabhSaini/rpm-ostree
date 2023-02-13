#!/bin/bash
set -xeuo pipefail
# Pull the latest FCOS build, unpack its container image, and verify
# that we can re-encapsulate it as chunked.

ver=37.20230201.20.0
packaging_ver=37.20221111.20.0
compare_ver=37.20230131.20.0
container=quay.io/fedora/fedora-coreos:${ver}

tmpdir=/tmp/coreTest-${ver}
p_tmpdir=/tmp/coreTest-${packaging_ver}
mkdir -p ${tmpdir}
cd ${tmpdir}
ostree --repo=repo init
cat /etc/ostree/remotes.d/fedora.conf >> repo/config

# Pull and unpack the ostree content, discarding the container wrapping
ostree container unencapsulate --write-ref=testref --repo=repo ostree-unverified-image:containers-storage:${container}

# Re-pack it as a (chunked) container
start=`date +%s.%N`
/home/redhat/work/dev-updates-remoting/rpm-ostree/rpm-ostree compose container-encapsulate --compare-with-build=oci:/tmp/coreTest-${compare_ver}/test.oci --prior-build=oci:/tmp/coreTest-${packaging_ver}/test.oci --repo=repo testref oci:${tmpdir}/test.oci
end=`date +%s.%N`
runtime=$( echo "$end - $start" | bc -l )
skopeo inspect oci:${tmpdir}/test.oci | jq '.LayersData | .[0].Annotations.Content' > annotation_ostree.txt
grep -qFe ostree_commit annotation_ostree.txt
skopeo inspect --config oci:${tmpdir}/test.oci | jq '.rootfs.diff_ids' > layersDiffids.txt
echo ok
