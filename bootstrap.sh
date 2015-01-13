
#
# Metrilyx bootstrap script
#   This script installs the required pre-requisites to install and run Metrilyx
#
# THIS IS STILL IN PROGRESS - SPECIFICALLY FOR DEBIAN BASED SYSTEMS
#
# Boostrap
#     curl http://metrilyx.github.io/bootstrap.sh | bash
#
# Bootstrap and Install
#     curl http://metrilyx.github.io/bootstrap.sh | bash -s -- install
#

INSTALL_TIME=$(date '+%d%b%Y_%H%M%S');

RPM_PKGS="git gcc gcc-c++ gcc-gfortran atlas-devel blas-devel libffi libffi-devel libuuid uuid python-setuptools python-devel";
DEB_PKGS="build-essential make g++ gfortran libuuid1 uuid-runtime python-setuptools python-dev libpython2.7 python-pip git-core libffi-dev libatlas-dev libblas-dev python-numpy"


METRILYX_SRC_URL="https://github.com/Ticketmaster/metrilyx-2.0";
METRILYX_CFG="/opt/metrilyx/etc/metrilyx/metrilyx.conf";
METRILYX_DEFAULT_DB="/opt/metrilyx/data/metrilyx.sqlite3";

DISTRO=""
CODENAME=""
## Redhat, CentOS
[ -f "/etc/redhat-release" ] && {
    DISTRO=$(cat /etc/redhat-release  | cut -f 1 -d ' ' | tr '[:upper:]' '[:lower:]');
    if [ "$DISTRO" == "red" ]; then DISTRO="redhat"; fi
}
## Oracle
[ -f "/etc/oracle-release" ] && DISTRO="oracle";
## Debian
[ -f "/etc/debian_version" ] && DISTRO="debian";
## Ubuntu
UBUNTU_RELEASE_FILE="/etc/lsb-release"
[ -f "$UBUNTU_RELEASE_FILE" ] && {
    grep "DISTRIB_ID" $UBUNTU_RELEASE_FILE && DISTRO=$(grep 'DISTRIB_ID=' $UBUNTU_RELEASE_FILE | cut -d '=' -f 2 | tr '[:upper:]' '[:lower:]');
    grep "DISTRIB_CODENAME" $UBUNTU_RELEASE_FILE && CODENAME=$(grep 'DISTRIB_CODENAME=' $UBUNTU_RELEASE_FILE | cut -d '=' -f 2 | tr '[:upper:]' '[:lower:]');
}

if [ "$DISTRO" == "" ];then
    echo "Could not determine OS distribution: $DISTRO";
    exit 1;
else
    echo -e "\n Distribution: $DISTRO\n";
fi

NGINX_PKG_URL="http://nginx.org/packages";
NGINX_CONF_DIR="/etc/nginx/conf.d";
NGINX_DEFAULT_CONF="${NGINX_CONF_DIR}/default.conf";
NGINX_REPO_RPM_URL="${NGINX_PKG_URL}/${DISTRO}/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm";

install_nginx_rpm() {
    ## DISTRO: centos, oracle, rhel
    [ -f "/etc/yum.repos.d/nginx.repo" ] || {
        yum -y install "$NGINX_REPO_RPM_URL" && yum -y install nginx;
        chkconfig nginx on;
    }
}

install_nginx_deb() {

    if [ "$CODENAME" == "" ]; then
        echo "Could not determine codename for $DISTRO!";
        exit 2;
    fi

    NGINX_SOURCES_LIST="/etc/apt/sources.list.d/nginx.list";

    ## Add nginx repo key
    NGINX_KEY_NAME="nginx_signing.key";
    NGINX_SGN_KEY="http://nginx.org/keys/$NGINX_KEY_NAME";

    [ -f "$NGINX_SOURCES_LIST" ] || {
        wget "$NGINX_SGN_KEY" && sudo apt-key add $NGINX_KEY_NAME && rm -rf $NGINX_KEY_NAME;
        sudo sh -c 'echo -e "\ndeb ${NGINX_PKG_URL}/${DISTRO}/ ${CODENAME} nginx\ndeb-src ${NGINX_PKG_URL}/${DISTRO}/ ${CODENAME} nginx\n" > $NGINX_SOURCES_LIST'
        sudo apt-get update -qq;
    }

    ## Install nginx
    sudo apt-get install -y nginx;
}

install_nginx() {
    if [[ ( "$DISTRO" == "centos" ) || ( "$DISTRO" == "oracle" ) || ( "$DISTRO" == "rhel" ) || ( "$DISTRO" == "redhat" ) ]]; then
        install_nginx_rpm;
    else
        install_nginx_deb;
    fi
    [ -f "$NGINX_DEFAULT_CONF" ] && mv "${NGINX_DEFAULT_CONF}" "${NGINX_DEFAULT_CONF}.disabled";
}

bootstrap_metrilyx_rpm() {
    yum -y install $RPM_PKGS;
}

bootstrap_metrilyx_deb() {
    sudo apt-get update -qq
    sudo apt-get install -y $DEB_PKGS;
}

bootstrap_metrilyx() {
    if [ "$1" != "nonginx" ]; then 
        install_nginx
    fi
    if [[ ( "$DISTRO" == "centos" ) || ( "$DISTRO" == "oracle" ) || ( "$DISTRO" == "rhel" ) || ( "$DISTRO" == "redhat" ) ]]; then
        bootstrap_metrilyx_rpm;
        which pip || easy_install pip;
        pip install "numpy>=1.6.1";
    else
        bootstrap_metrilyx_deb;
    fi
}

post_install_message() {
    CFGFILE=$1
    echo -e "\n * Edit the configuration file:\n\t$CFGFILE\n\n * Start the metrilyx service:\n\t/etc/init.d/metrilyx start\n"
}

copy_sample_configs() {
    echo -e " * Copying sample configs...\n"
    [ -f "$METRILYX_CFG" ] || cp "${METRILYX_CFG}.sample" "$METRILYX_CFG";
    [ -f "$METRILYX_DEFAULT_DB" ] || cp "${METRILYX_DEFAULT_DB}.default" "$METRILYX_DEFAULT_DB";
}

install_metrilyx() {
    if [ "$1" == "install" ]; then
        echo " * Installing Metrilyx...";
        BRANCH=$2;
        
        if [ "$BRANCH" == "" ]; then
            sudo pip install "git+${METRILYX_SRC_URL}.git" && copy_sample_configs && post_install_message $METRILYX_CFG;
        else
            sudo pip install "git+${METRILYX_SRC_URL}.git@${BRANCH}" && copy_sample_configs && post_install_message $METRILYX_CFG;
        fi
    fi
}


#### Main ####

bootstrap_metrilyx $1;

# params
#   1 'install'
#   2  git branch/tag
#
install_metrilyx $1 $2;

