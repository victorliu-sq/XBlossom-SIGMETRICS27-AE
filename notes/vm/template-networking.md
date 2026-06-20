# AWS Template Networking

When launching an instance from a template, the networking section still needs
manual selections. Do not skip these fields.

## Required Selections

| Field | Selection                                                                                   |
| --- |---------------------------------------------------------------------------------------------|
| Subnet | Select the second subnet option.                                                            |
| Availability zone | Select `us-east-2b` / `2b`.                                                                 |
| Firewall / security group | Select an existing security group. Use the `launch-wizard-8` security group for this setup. |

After these three networking choices are set, continue with the launch.
