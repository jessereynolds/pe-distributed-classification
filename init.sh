vagrant oscar init
vagrant oscar init-vms \
  --master master.a.dnc.example=puppetlabs/centos-7.0-64-nocm \
  --master master.b.dnc.example=puppetlabs/centos-7.0-64-nocm \
  --agent  agent1.b.dnc.example=puppetlabs/centos-7.0-64-nocm \
  --pe-version 2015.3.1
echo "Now, fix the master hostname for the agents in config/roles.yaml (see https://github.com/oscar-stack/oscar/issues/44)"
echo 'Also, disable iptables but adding the following provisioner to each role: '
echo '  - {type: shell, inline: "systemctl disable firewalld ; systemctl stop firewalld"}'
