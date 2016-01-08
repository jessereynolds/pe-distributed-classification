# Distributed Node Classification in Puppet Enterprise

You have geographically separated puppet masters that need to be semi-autonomous whilst having node classifier groups updated from a central source of truth. But you don't always have a reliable, or fast, connection back to the central point. To spell this out a bit more, you want / need to have the following:
- a single source of truth for classification that all masters consume.
- masters able to keep compiling with the latest available classification data even when the wan links are down for a while.
- avoid doing NC requests over the WAN due to data size, latency, and reliability constraints.
- the lightest and most reliable distributed puppet architecture possible while maintaining a single source of truth for node classification data.
- regions to be semi-autonomous, readonly, and update from a central point.
- be aware of failing updates.


Some possible approaches / components:
- classifier groups synchronisation with status shown in wrapper of central console UI
- enable reading of the node classification cache with `node_cache_terminus=yaml` (but what about cache expiry?)
- use replicated nc database but avoid puppet db replication (if our postgres and puppet config modules can configure separate postgres instance for NC or puppet db)
- use a distributed object store (eg redis, memcached) to replicate classification data
- polling daemon to retrieve classification data and write to yaml file or distributed object store
- caching proxy for classification data (local daemon) (but puppet already caches node terminus results and can re-use this with `node_cache_terminus=yaml` so this is possibly equivalent, though we might be able to expose more useful cache expiry controls)


## Investigations

### Have puppet master use cached node classification data

`node_cache_terminus=yaml` - the default is 'write_only_yaml' which of course doesn't allow puppet master to use the cached nodes. Tested as follows:
- install PE 2015.3.0 rc4
- `puppet agent -t` on master - no errors
- stop puppet agent `systemctl stop puppet`
- modify `/etc/puppetlabs/puppet/classifier.yaml` to point to an invalid api endpoint (change port from `4433` to `44333`)
- restart puppet server `systemctl restart pe-puppetserver`
- `puppet agent -t` on master - errors expected "Error: Could not retrieve catalog from remote server: Error 400 on SERVER: Failed when searching for node master.vm: Classification of master.vm failed due to a Node Manager service error."
- edit `/etc/puppetlabs/puppet/puppet.conf` and add the following to the master section: `node_cache_terminus=yaml`
- `puppet agent -t` on master - success! no errors.

The above shows that the puppet master can be configured to use a cached copy of the classification data for nodes for which it already has data. What happens if there is no cached node classification data? Lets see:

- `rm /opt/puppetlabs/server/data/puppetserver/yaml/node/master.vm.yaml`
- modify `/etc/puppetlabs/puppet/classifier.yaml` to point to an invalid api endpoint (change port from `4433` to `44333`)
- restart puppet server `systemctl restart pe-puppetserver`
- puppet run gets the same error as before "Error: Could not retrieve catalog from remote server: Error 400 on SERVER: Failed when searching for node master.vm: Classification of master.vm failed due to a Node Manager service error."

### Work out when puppet master invalidates the cached node classification data

With node classification cache readable (`node_cache_terminus=yaml`) when does the puppet master invalidate this cache and update the node's classification cache?

Basic plan:
- Delete cached classificaion data for test node
- Puppet run - observe new cache file being created
- Change classification for test node in the console (add a class)
- Puppet run - what happens? (request to classifier end point? new cache file? or classification change not enforced on test node?)
- If no change, repeat puppet runs over a period of time. Increase verbosity of puppet master's logs and try and discern what it's doing. If it has an expiry on the cache, where is that configured?

Adding class `puppet_enterprise::symlinks` to PE Master group:
- rm cache file
- puppet run
- add class `puppet_enterprise::symlinks` to the PE Master group
- puppet run - observe the class has not been added to the cache file (although the cache file has been updated with latest facts)
- rm cache file
- puppet run - observe that the class has now been added to the cache file

With an invalid parameter (causing compilation failure):
- add an invalid parameter to a class (eg java_args: "-Dfoo-bar" in puppet_enterprise::profile::master in "PE Master" group)
- rm the cache
- puppet run - errors
- revert the nc change (remove the java_args parameter)
- puppet run - still errors
- rm the cache
- puppet run - back to normal

Summary:
- if node classification cache file is present, master will use it and make no requests of the node classifier
- the only way to invalidate the cache that I'm aware of is to delete the node's cache file

### Can puppet db be configured to use a separate postgres instance?

So that it can have replication disabled.

### Prototype classification groups sync using api

Use the groups endpoint on the central and satellite node classifiers to one-way push out classification groups:
- fetch all groups on central nc
- delete all groups on satellite nc
- recreate all groups on satellite nc using groups from central nc

### Adding classification groups with classes that haven't been sync'd from the master yet

What happens if you add a group to the node classifier via the api, and you reference classes that it doesn't know about yet?

- [set synchronization period to 0](http://docs.puppetlabs.com/pe/latest/console_config.html#tuning-the-classifier-synchronization-period) (never synchronise)
- use the groups endpoint to create a new group referencing a new class

### PEE - view status of classifier sync

Wrapper for the Console UI that adds classification sync status.

## References

- [External Node Classifiers](https://docs.puppetlabs.com/guides/external_nodes.html)
- [Groups Endpoint of the Node Classifier Service](https://docs.puppetlabs.com/pe/latest/nc_groups.html)
- [Console Config - tuning the classifier synchronisation period](http://docs.puppetlabs.com/pe/latest/console_config.html#tuning-the-classifier-synchronization-period)
- [Node Classifier Architecture](https://confluence.puppetlabs.com/display/ENG/Node+Classifier+Architecture)

## Resources
- [puppetclassify ruby gem](https://rubygems.org/gems/puppetclassify), [Source](https://github.com/puppetlabs/puppet-classify)

