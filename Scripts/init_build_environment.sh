#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) ImmortalWrt.org

DEFAULT_COLOR="\033[0m"
BLUE_COLOR="\033[36m"
GREEN_COLOR="\033[32m"
RED_COLOR="\033[31m"
YELLOW_COLOR="\033[33m"

function __error_msg() {
	echo -e "${RED_COLOR}[ERROR]${DEFAULT_COLOR} $*"
}

function __info_msg() {
	echo -e "${BLUE_COLOR}[INFO]${DEFAULT_COLOR} $*"
}

function __success_msg() {
	echo -e "${GREEN_COLOR}[SUCCESS]${DEFAULT_COLOR} $*"
}

function __warning_msg() {
	echo -e "${YELLOW_COLOR}[WARNING]${DEFAULT_COLOR} $*"
}

function check_system() {
	__info_msg "Checking system info..."

	VERSION_CODENAME="$(source /etc/os-release; echo "$VERSION_CODENAME")"

	case "$VERSION_CODENAME" in
	"bionic")
		GCC_VERSION="9"
		LLVM_VERSION="18"
		NODE_DISTRO="$VERSION_CODENAME"
		NODE_KEY="nodesource.gpg.key"
		NODE_VERSION="18"
		UBUNTU_CODENAME="$VERSION_CODENAME"
		VERSION_PACKAGE="libpython3.6-dev python2.7 python3.6"
		;;
	"buster")
		DISTRO_PREFIX="debian-archive/"
		DISTRO_SECUTIRY_PATH="buster/updates"
		GCC_VERSION="9"
		LLVM_VERSION="18"
		UBUNTU_CODENAME="bionic"
		VERSION_PACKAGE="python2"
		;;
	"focal")
		GCC_VERSION="10"
		LLVM_VERSION="18"
		UBUNTU_CODENAME="$VERSION_CODENAME"
		VERSION_PACKAGE="python2"
		;;
	"bullseye")
		BPO_FLAG="-t $VERSION_CODENAME-backports"
		BPO_DISTRO_PREFIX="debian-archive/"
		GCC_VERSION="10"
		LLVM_VERSION="18"
		UBUNTU_CODENAME="focal"
		VERSION_PACKAGE="python2"
		;;
	"jammy")
		GCC_VERSION="10"
		LLVM_VERSION="18"
		UBUNTU_CODENAME="$VERSION_CODENAME"
		VERSION_PACKAGE="python2"
		;;
	"bookworm")
		APT_COMP="non-free-firmware"
		BPO_FLAG="-t $VERSION_CODENAME-backports"
		GCC_VERSION="12"
		LLVM_VERSION="18"
		UBUNTU_CODENAME="jammy"
		;;
	"noble")
		GCC_VERSION="13"
		LLVM_VERSION="18"
		UBUNTU_CODENAME="$VERSION_CODENAME"
		;;
	"trixie")
		APT_COMP="non-free-firmware"
		BPO_FLAG="-t $VERSION_CODENAME-backports"
		GCC_VERSION="13"
		LLVM_VERSION="18"
		UBUNTU_CODENAME="noble"
		;;
	*)
		__error_msg "Unsupported OS, use Ubuntu 20.04 instead."
		exit 1
		;;
	esac

	[ "$(uname -m)" == "x86_64" ] || { __error_msg "Unsupported architecture, use AMD64 instead." && exit 1; }

	[ "$(whoami)" == "root" ] || { __error_msg "You must run this script as root." && exit 1; }
}

function check_network() {
	__info_msg "Checking network..."

	curl -s "myip.ipip.net" | grep -qo "中国" && CHN_NET=1
	curl --connect-timeout 10 "baidu.com" > "/dev/null" 2>&1 || { __warning_msg "Your network is not suitable for compiling OpenWrt!"; }
	curl --connect-timeout 10 "google.com" > "/dev/null" 2>&1 || { __warning_msg "Your network is not suitable for compiling OpenWrt!"; }
}

function update_apt_source() {
	__info_msg "Updating apt source lists..."
	set -x

	apt update -y
	apt install -y apt-transport-https gnupg2

	mkdir -p "/etc/apt/keyrings"
	mkdir -p "/etc/apt/sources.list.d"
	mkdir -p "/etc/apt/trusted.gpg.d"

	if [ -n "$CHN_NET" ]; then
		mv "/etc/apt/sources.list" "/etc/apt/sources.list.bak"
		mv "/etc/apt/sources.list.d/debian.sources" "/etc/apt/sources.list.d/debian.sources.bak"
		mv "/etc/apt/sources.list.d/ubuntu.sources" "/etc/apt/sources.list.d/ubuntu.sources.bak"

		if [ "$VERSION_CODENAME" == "$UBUNTU_CODENAME" ]; then
cat <<EOF >"/etc/apt/sources.list"
deb https://mirrors.cloud.tencent.com/ubuntu/ $VERSION_CODENAME main restricted universe multiverse
deb-src https://mirrors.cloud.tencent.com/ubuntu/ $VERSION_CODENAME main restricted universe multiverse
deb https://mirrors.cloud.tencent.com/ubuntu/ $VERSION_CODENAME-security main restricted universe multiverse
deb-src https://mirrors.cloud.tencent.com/ubuntu/ $VERSION_CODENAME-security main restricted universe multiverse
deb https://mirrors.cloud.tencent.com/ubuntu/ $VERSION_CODENAME-updates main restricted universe multiverse
deb-src https://mirrors.cloud.tencent.com/ubuntu/ $VERSION_CODENAME-updates main restricted universe multiverse
deb https://mirrors.cloud.tencent.com/ubuntu/ $VERSION_CODENAME-backports main restricted universe multiverse
deb-src https://mirrors.cloud.tencent.com/ubuntu/ $VERSION_CODENAME-backports main restricted universe multiverse
EOF
		elif [ "$VERSION_CODENAME" == "buster" ]; then
cat <<EOF >"/etc/apt/sources.list"
deb https://mirrors.tuna.tsinghua.edu.cn/debian-elts $VERSION_CODENAME main contrib non-free
EOF
			curl -fsL "https://deb.freexian.com/extended-lts/archive-key.gpg" -o "/etc/apt/trusted.gpg.d/extended-lts.gpg"
		else
cat <<EOF >"/etc/apt/sources.list"
deb https://mirrors.cloud.tencent.com/${DISTRO_PREFIX}debian/ $VERSION_CODENAME main contrib non-free${APT_COMP:+ $APT_COMP}
deb-src https://mirrors.cloud.tencent.com/${DISTRO_PREFIX}debian/ $VERSION_CODENAME main contrib non-free${APT_COMP:+ $APT_COMP}
deb https://mirrors.cloud.tencent.com/${DISTRO_PREFIX}debian-security ${DISTRO_SECUTIRY_PATH:-$VERSION_CODENAME-security} main contrib non-free${APT_COMP:+ $APT_COMP}
deb-src https://mirrors.cloud.tencent.com/${DISTRO_PREFIX}debian-security ${DISTRO_SECUTIRY_PATH:-$VERSION_CODENAME-security} main contrib non-free${APT_COMP:+ $APT_COMP}
deb https://mirrors.cloud.tencent.com/${DISTRO_PREFIX}debian/ $VERSION_CODENAME-updates main contrib non-free${APT_COMP:+ $APT_COMP}
deb-src https://mirrors.cloud.tencent.com/${DISTRO_PREFIX}debian/ $VERSION_CODENAME-updates main contrib non-free${APT_COMP:+ $APT_COMP}
deb https://mirrors.cloud.tencent.com/${BPO_DISTRO_PREFIX:-$DISTRO_PREFIX}debian/ $VERSION_CODENAME-backports main contrib non-free${APT_COMP:+ $APT_COMP}
deb-src https://mirrors.cloud.tencent.com/${BPO_DISTRO_PREFIX:-$DISTRO_PREFIX}debian/ $VERSION_CODENAME-backports main contrib non-free${APT_COMP:+ $APT_COMP}
EOF
		fi
	else
		if [ "$VERSION_CODENAME" == "buster" ]; then
			mv "/etc/apt/sources.list" "/etc/apt/sources.list.bak"
cat <<EOF >"/etc/apt/sources.list"
deb https://deb.freexian.com/extended-lts $VERSION_CODENAME main contrib non-free
EOF
			curl -fsL "https://deb.freexian.com/extended-lts/archive-key.gpg" -o "/etc/apt/trusted.gpg.d/extended-lts.gpg"
		fi
	fi

cat <<EOF >"/etc/apt/sources.list.d/nodesource.list"
deb https://deb.nodesource.com/node_${NODE_VERSION:-22}.x ${NODE_DISTRO:-nodistro} main
EOF
	curl -fsL "https://deb.nodesource.com/gpgkey/${NODE_KEY:-nodesource-repo.gpg.key}" -o "/etc/apt/trusted.gpg.d/nodesource.asc"

cat <<EOF >"/etc/apt/sources.list.d/yarn.list"
deb https://dl.yarnpkg.com/debian/ stable main
EOF
	curl -fsL "https://dl.yarnpkg.com/debian/pubkey.gpg" -o "/etc/apt/trusted.gpg.d/yarn.asc"

	case "$VERSION_CODENAME" in
	"bionic"|"buster")
cat <<EOF >"/etc/apt/sources.list.d/gcc-toolchain.list"
deb https://ppa.launchpadcontent.net/ubuntu-toolchain-r/test/ubuntu $UBUNTU_CODENAME main
deb-src https://ppa.launchpadcontent.net/ubuntu-toolchain-r/test/ubuntu $UBUNTU_CODENAME main
EOF
		curl -fsL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x1e9377a2ba9ef27f" -o "/etc/apt/trusted.gpg.d/gcc-toolchain.asc"
		;;
	esac

cat <<EOF >"/etc/apt/sources.list.d/git-core-ubuntu-ppa.list"
deb https://ppa.launchpadcontent.net/git-core/ppa/ubuntu $UBUNTU_CODENAME main
deb-src https://ppa.launchpadcontent.net/git-core/ppa/ubuntu $UBUNTU_CODENAME main
EOF
	curl -fsL "
