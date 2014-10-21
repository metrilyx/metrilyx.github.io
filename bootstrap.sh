
#
# Metrilyx bootstrap script
#   This script installs the required pre-requisites to install and run Metrilyx
#
# THIS IS STILL IN PROGRESS - SPECIFICALLY FOR DEBIAN BASED SYSTEMS
#

RPM_PKGS="git gcc gcc-c++ gcc-gfortran atlas-devel blas-devel libffi libffi-devel libuuid uuid python-setuptools python-devel";
DEB_PKGS="make g++ gfortran libuuid1 uuid-runtime python-setuptools python-dev libpython-dev git-core libffi-dev libatlas-dev libblas-dev python-numpy"

NGINX_CONF_DIR="/etc/nginx/conf.d"

DISTRO=""
[ -f "/etc/redhat-release" ] && DISTRO=$(cat /etc/redhat-release  | cut -f 1 -d ' ' | tr '[:upper:]' '[:lower:]')

[ -f "/etc/debian_version" ] && DISTRO="debian"
grep "ubuntu" /etc/apt/sources.list && DISTRO="ubuntu" 

echo "Distribution: $DISTRO"

install_nginx_rpm() {
    ## DISTRO: centos, oracle, rhel
	rpm -qa | grep 'nginx-release' || { yum -y install "http://nginx.org/packages/${DISTRO}/6/noarch/RPMS/nginx-release-${DISTRO}-6-0.el6.ngx.noarch.rpm" && yum -y install nginx;
		chkconfig nginx on;
	}
}

install_nginx_deb() {
		
	CODENAME=${1:-"trusty"};

	SOURCES_LIST="/etc/apt/sources.list";
	NGINX_SRC_URL="http://nginx.org/packages";

	apt-key add "http://nginx.org/keys/nginx_signing.key";
    
    ## Add nginx repository
	grep "$NGINX_SRC_URL" $SOURCES_LIST || { 
	    echo -e "\ndeb ${NGINX_SRC_URL}/${DISTRO}/ ${CODENAME} nginx\ndeb-src ${NGINX_SRC_URL}/${DISTRO}/ ${CODENAME} nginx\n" >> $SOURCES_LIST;
	    apt-get update;
    }
    ## Install nginx
    apt-get install -y nginx;
}

install_nginx() {
	if [[ ( "$DISTRO" == "centos" ) || ( "$DISTRO" == "oracle" ) || ( "$DISTRO" == "rhel" ) ]]; then
		install_nginx_rpm;
	else
		install_nginx_deb;
	fi
	[ -f "/etc/nginx/conf.d/default.conf" ] && mv ${NGINX_CONF_DIR}/default.conf ${NGINX_CONF_DIR}/default.conf.disabled;
}

bootstrap_metrilyx_rpm() {
	for PKG in $RPM_PKGS; do
		rpm -qa | grep $PKG || yum -y install $PKG
	done
}	

bootstrap_metrilyx_deb() {
	apt-get install -y $DEB_PKGS;
}

bootstrap_metrilyx() {
	if [[ ( "$DISTRO" == "centos" ) || ( "$DISTRO" == "oracle" ) || ( "$DISTRO" == "rhel" ) ]]; then
		bootstrap_metrilyx_rpm;
	    which pip || easy_install pip;
	    pip install "numpy>=1.6.1";    
	else
		bootstrap_metrilyx_deb;
	    which pip || easy_install pip;
	fi
}

install_metrilyx() {
	pip install git+https://github.com/Ticketmaster/metrilyx-2.0.git
}

install_nginx;
bootstrap_metrilyx;

if [ "$1" == "install" ]; then
	echo " * Installing Metrilyx...";
	install_metrilyx;
fi

