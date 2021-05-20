#!/bin/sh

# Run on VM to bootstrap Puppet Agent nodes
if ps aux | grep "puppet agent" | grep -v grep 2> /dev/null
then
    echo "Puppet Agent is already installed. Moving on..."
else
    # Install Puppet Agent
    rpm -Uvh https://yum.puppet.com/puppet6-release-el-7.noarch.rpm
    sudo yum install -y puppet-agent
fi
 
if cat /etc/crontab | grep puppet 2> /dev/null
then
    echo "Puppet Agent is already configured. Exiting..."
else
    # NTP install and configure server
    sudo yum -y install ntpdate
    ntpdate 0.centos.pool.ntp.org
    sudo yum -y update && sudo yum -y upgrade
 
    # Configure /etc/hosts file
    echo "" | sudo tee --append /etc/hosts 2> /dev/null && \
    echo "# Host config for Puppet Master and Agent Nodes" | sudo tee --append /etc/hosts 2> /dev/null && \
    echo "192.168.66.10  poc-puppet-master-0.arqcloud.local  poc-puppet-master-0" | sudo tee --append /etc/hosts 2> /dev/null && \
    echo "192.168.66.20  poc-puppet-client-0.arqcloud.local  poc-puppet-client-0" | sudo tee --append /etc/hosts 2> /dev/null && \
    echo "192.168.66.21  poc-puppet-client-1.arqcloud.local  poc-puppet-client-1" | sudo tee --append /etc/hosts 2> /dev/null
 
    # Add optional alternate DNS names to /etc/puppetlabs/puppet/puppet.conf
    echo $HOSTNAME
    sudo sed -i "s/.*\[main\].*/&\ncertname = ${HOSTNAME}.arqcloud.local,poc-puppet-master-0/" /etc/puppetlabs/puppet/puppet.conf
    sudo sed -i 's/.*\[main\].*/&\nserver = poc-puppet-master-0.arqcloud.local/' /etc/puppetlabs/puppet/puppet.conf
    sudo sed -i 's/.*\[main\].*/&\nenvironment = production/' /etc/puppetlabs/puppet/puppet.conf
    sudo sed -i 's/.*\[main\].*/&\nruninterval = 3m/' /etc/puppetlabs/puppet/puppet.conf

    # Start puppet agent on the node and make it start automatically on system boot.
    puppet resource service puppet ensure=running enable=true

    # FW conf and restart
    sudo firewall-cmd --permanent --add-port=8140/tcp
    sudo firewall-cmd --reload
    sudo sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
    sudo telinit 6
fi