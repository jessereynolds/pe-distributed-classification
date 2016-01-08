# What is this?

This is an environment managed by Vagrant and Oscar for testing various approaches to distribued node classification in geo-diverse Puppet Enterprise installations. [Do you want to know more](distributed-classification.markdown)?

# Prerequisites

- VirtualBox (tested with 5.0.2) or VMWare Fusion should work too
- Vagrant (tested with 1.7.4)
- Vagrant Plugins:
-- oscar
-- vagrant-hosts
- > 8GB free memory

# Using

```
vagrant up
vagrant provision
```

Add hosts entries for the VMs to your /etc/hosts (optional):

```
vagrant hosts puppetize | sudo puppet apply
```

# How this was made:

```bash
bash init.sh
# fix roles.yaml as per instructions output by init.sh (kill firewall, increase memory, fix master fqdn in agent)
vagrant up
vagrant provision
vagrant hosts puppetize | sudo puppet apply
```

This sets up the following hosts:

- master.a.dnc.example (managed by self)
- master.b.dnc.example (managed by self)
- agent1.b.dnc.example (managed by master.b)

TODO: Next Steps:

- set up control repo deploying to both masters
- retire CA on master.b, have it use master.a
- try sync'ing the classification rules from master.a to master.b via api
- try and make console 'read only' on master.b

