#!/bin/bash
#------------------------------------------------------------------------------
# Description: Install and setup ansible venv with python 3 and pip
# License: MIT
# Platform: rhel/centos 7/8
# Author: Mark Bolwell
# Requirements: Root user and access to update packages and install from pip - proxy is ok
# if running older ubuntu e.g. 18 then ensure repositorys are update dto archive
#------------------------------------------------------------------------------

# Change if required
#ignore_os_check=true
ansible_version=2.9.12
python_major_vers=3
python_minor_vers=6

## PROXY
# Please add proxy settings suitable for pip.conf if not found in yum.conf
# update the line below remove user:password if not authenticated
#MANUAL_PROXY="[global]\nproxy = http://user:password@proxy_name:port"

#
install_log=./install_ansible.log

## These shouldnt need changing unless requirements for ansible
## or ansible-lockdown change

python_pkg=$python_major_vers$python_minor_vers
rh_ansible_deps="python$python_pkg python$python_pkg-devel libffi-devel openssl-devel gcc git"
deb_ansible_deps="python3 python3-pip libssl-dev"

# pip installation and module versions
# Setup for std linux and window connections
# if require more e.g. aws, azure these can be added to the list below
pip_std_modules="
ansible==$ansible_version
certifi==2020.6.20
cffi==1.14.2
chardet==3.0.4
cryptography==3.0
idna==2.10
Jinja2==3.0.1
jmespath==0.10.0
MarkupSafe==2.0.1
ntlm-auth==1.5.0
passlib==1.7.2
pycparser==2.20
pywinrm==0.4.1
PyYAML==5.3.1
requests==2.24.0
requests-ntlm==1.1.0
six==1.15.0
urllib3==1.25.10
xmltodict==0.12.0
"
pip_xtra_modules=""




#-------------------------------------

usage() {
    # Provide usage detail to user

sed 's/^        //' <<EOF
        ansible_install.sh - Install or remove ansible packages & modules.
        Usage: ansible_setup.sh [-h] [-i] [-p] [-r]
        Arguments:
          -h    Print this message
          -i    Install/update packages & download modules.
          -p  update/install pip modules only
          -r    Remove packages & modules.
EOF
}
############### Main Functions ##################
 echo $UID
 echo $EUID
check_for_root_os() {
    echo "------------------------------"
    echo "Root user and OS Version check"
    echo "------------------------------"
    # Check to make sure we're being run by root.
    if [ $(id -u) -ne  0 ]; then
    echo "Please run as root"
    exit
    fi
    # Check to make sure correct OS version
    if [ -f /etc/os-release ]; then
        if   [ `grep ID_LIKE /etc/os-release | grep -c fedora` -eq 1 ]; then
            export OS_FLAV=RH;
        elif [ `grep ID /etc/os-release | grep -ci ubuntu` -eq 1 ]; then
            export OS_FLAV=DEB;
        else
            echo "Incorrect OS - Script only runs on fedora or debian variants"; exit 1
        fi

    elif [ -n "$ignore_os_check" ]; then
       echo "---- OS Check ignore option set ----"
    fi
    echo "------- Completed -------"
}

check_for_proxy() {
    echo "------------------------------------"
    echo "Check for proxy server configuration"
    echo "------------------------------------"
    # Check to see if a proxy server is defined and if so return it.
    if [ -n "$MANUAL_PROXY" ]; then
       echo "----- Manual Proxy Server Variable Set -----"
    elif [ `grep -c ^proxy /etc/yum.conf` > 0 ]; then
            PROXY_SETTINGS=`grep ^proxy= /etc/yum.conf`
    fi
    echo "------- Completed -------"
}

stop_ansible_os_pkg() {
    if [ "$OS_FLAV" = 'RH' ]; then
    # Check to see if Ansible is excluded in yum.conf
    echo "------------------------------------------"
    echo "Ensure ansible OS package ignored: Started"
    echo "------------------------------------------"

        if [ `grep -v "#" /etc/yum.conf | grep -c ansible` = 0 ]; then
            echo -e "## Exclude ansible for OS pkg install - dependency issues when patching ## \nexclude=ansible*" >> /etc/yum.conf;
        fi
        # Check to see if Ansible is excluded in dnf.conf
        if [ -f /etc/dnf.conf ]; then
            if [ `grep -v "#" /etc/dnf.conf | grep -c ansible` = 0 ]; then
            echo -e "## Exclude ansible for OS pkg install - dependency issues when patching ## \nexclude=ansible*" >> /etc/dnf.conf;
            fi
        fi
    echo "------- Completed -------"
    fi
}

install_os_deps() {
    echo "-----------------------------------------------"
    echo "Install python$python_pkg and ansible OS dependencies: Started"
    echo "-----------------------------------------------"
    if [ "$OS_FLAV" = 'RH' ]; then
      yum install $rhansible_deps -y >> $install_log 2>&1 &&
        if [ `echo $?` = 0 ]; then
          echo "------- Completed -------"
        else
          echo "--- Please check $install_log for errors ---"
        fi
    elif [ "$OS_FLAV" =  'DEB' ]; then
      apt install -y $deb_ansible_deps  >> $install_log 2>&1 &&
        if [ `echo $?` = 0 ]; then
          echo "------- Completed -------"
        else
          echo "--- Please check $install_log for errors ---"
        fi
    fi

}

install_pip_ansible_os() {
    echo "--------------------------------------------------------"
    echo "Ansible Pip module install: Started - this may take time"
    echo "--------------------------------------------------------"
    check_for_proxy
    if [ -z $PROXY_SETTINGS ];then
       if [ ! -d ~/.pip ];then
            mkdir ~/.pip;
            echo  "[global]\n$PROXY_SETTINGS" > ~/.pip/pip.conf
       fi
    fi
    umask 0022;
    pip3 install $pip_std_modules $pip_xtra_modules >> $install_log 2>&1
    if [ `echo $?` != 0 ]; then
        echo "----pip install failure please check $install_log ----"
    else
        echo "------- Completed -------"
    fi

}

remove_pip_ansible_os() {
    # Undo pip modules
    echo "--------------------------------------------------"
    echo "Pip Module Removal: Started"
    echo "--------------------------------------------------"
    pip3 uninstall -y $pip_std_modules $pip_xtra_modules
    echo "------- Completed -------"
}

ansible_update () {
    echo "--------------------------------------------------"
    echo "Ansible update Started"
    echo "--------------------------------------------------"
    install_pip_ansible_os
    echo "------- Completed -------"
}



final_checks() {
    # Check Installed Packages
    ok=0

    echo "--------------------------------------------------"
    echo "Ansible Base Install & Configuration: Completed"
    echo "--------------------------------------------------"
    echo ""
    return "${ok}"

}

main() {
#--------------------#
# Main Program Entry #
#--------------------#

    # Check for root user and OS type
    check_for_root_os


    # Check what the user is asking to do
    local opt
    while getopts :hipr opt; do
        case "${opt}" in
            h) usage ;;
            i) stop_ansible_os_pkg && install_os_deps && install_pip_ansible_os && final_checks ;;
            p) ansible_update ;;
            r) remove_pip_ansible_os ;;
        esac
    done
    [ "${OPTIND}" -eq 1 ] && usage # This checks for no opts passed
    shift $((OPTIND-1))

}


main $@