# SSH

## Elastic IP address
Elastic IP address may incur `REMOTE HOST IDENTIFICATION HAS CHANGED` warning.

Run the following command to address this issue for ip address `16.58.68.70` and `3.17.105.212`

```shell
ssh-keygen -f ~/.ssh/known_hosts -R 16.58.68.70
ssh-keygen -f ~/.ssh/known_hosts -R 3.17.105.212
```
or 
```shell
ssh-keyscan -H 16.58.68.70 3.17.105.212 >> ~/.ssh/known_hosts
```

## SSH Config

A cleaner setup is to put both hosts in `~/.ssh/config`:
```shell
Host aws-cpu
    HostName 16.58.68.70
    User ubuntu
    IdentityFile ~/Downloads/jiaxin-aws.pem

Host aws-gpu
    HostName 3.17.105.212
    User ubuntu
    IdentityFile ~/Downloads/jiaxin-aws.pem
```

This config can replace the tedious
```shell
ssh -i jiaxin-aws.pem ubuntu@16.58.68.70
ssh -i jiaxin-aws.pem ubuntu@3.17.105.212
```
into 
```shell
ssh aws-cpu
ssh aws-gpu
```


# Perf
## Use of Perf in AWS g7e
Perf cannot be used `/proc/sys/kernel/perf_event_paranoid = 4`

remote Linux permissions issue

```shell
echo 'kernel.perf_event_paranoid = -1' | sudo tee /etc/sysctl.d/99-perf.conf
sudo sysctl --system
```

Quick Check:
```shell
cat /proc/sys/kernel/perf_event_paranoid
```

## Perf Counter in AWS g7e
Old Mobile CPU profiling counter:
```bash
instructions
mem_load_retired.l3_miss
mem_load_retired.l3_hit
```

New Desktop CPU profiling counter
```bash
total instruction execution number -> instructions
LLC/L3 load misses                 -> mem_load_retired.l3_miss
LLC/L3 load hits                   -> mem_load_retired.l3_hit
LLC/L3 total load accesses         -> mem_load_retired.l3_hit + mem_load_retired.l3_miss
```

## NCU Counter in AWS g7e

Old A100 profiling counter:
```bash
sm__sass_thread_inst_executed.sum
dram__bytes_read.sum
```

New Blackwell GPU profiling counter
```bash
sm__sass_thread_inst_executed.sum
dram__bytes_op_read.sum
```

`ncu` requires `sudo` to execute