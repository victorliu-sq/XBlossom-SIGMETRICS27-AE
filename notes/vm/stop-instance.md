When an EC2 instance is stuck in stopping and even Force stop does not work, 
Try force stop once from CLI, not only the console:

```shell
aws ec2 stop-instances --instance-ids i-03175b41f169580e9 --force
```