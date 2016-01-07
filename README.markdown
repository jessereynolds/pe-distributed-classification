# Creating this environment:

```bash
bash init.sh
# fix roles.yaml as per instructions output by init.sh
vagrant up
vagrant provision
vagrant hosts puppetize | sudo puppet apply
```

This sets up the following hosts:

- master.a.dnc.example (managed by self)
- master.b.dnc.example (managed by self)
- agent1.b.dnc.example (managed by master.b)


