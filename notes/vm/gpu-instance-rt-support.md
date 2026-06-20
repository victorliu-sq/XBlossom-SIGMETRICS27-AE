# AWS GPU Instances and RT Hardware Support

Prices are copied from the attached AWS console screenshots. GPU names and GPU
counts are based on the AWS EC2 accelerated-computing instance specifications.

The "GPU supports RT" column means the GPU has dedicated hardware ray-tracing
support, such as NVIDIA RT cores or an equivalent hardware ray accelerator. It
does not mean that software ray tracing is impossible on GPUs marked "No".

| Instance type | On-demand Linux price | GPU name | GPU supports RT | GPU count |
|---|---:|---|---|---:|
| p6-b200.48xlarge | 113.9328 USD/hour | NVIDIA B200 | No | 8 |
| p5en.48xlarge | 63.296 USD/hour | NVIDIA H200 | No | 8 |
| p5e.48xlarge | - | NVIDIA H200 | No | 8 |
| p5.4xlarge | 6.88 USD/hour | NVIDIA H100 | No | 1 |
| p5.48xlarge | 55.04 USD/hour | NVIDIA H100 | No | 8 |
| p4d.24xlarge | 21.95764 USD/hour | NVIDIA A100 | No | 8 |
| gr6.4xlarge | 1.5392 USD/hour | NVIDIA L4 | Yes | 1 |
| gr6.8xlarge | 2.4464 USD/hour | NVIDIA L4 | Yes | 1 |
| g7e.2xlarge | 3.36312 USD/hour | NVIDIA RTX PRO Server 6000 | Yes | 1 |
| g7e.4xlarge | 3.99816 USD/hour | NVIDIA RTX PRO Server 6000 | Yes | 1 |
| g7e.8xlarge | 5.26824 USD/hour | NVIDIA RTX PRO Server 6000 | Yes | 1 |
| g7e.12xlarge | 8.28608 USD/hour | NVIDIA RTX PRO Server 6000 | Yes | 2 |
| g7e.24xlarge | 16.57216 USD/hour | NVIDIA RTX PRO Server 6000 | Yes | 4 |
| g7e.48xlarge | 33.14432 USD/hour | NVIDIA RTX PRO Server 6000 | Yes | 8 |
| g6e.xlarge | 1.861 USD/hour | NVIDIA L40S | Yes | 1 |
| g6e.2xlarge | 2.24208 USD/hour | NVIDIA L40S | Yes | 1 |
| g6e.4xlarge | 3.00424 USD/hour | NVIDIA L40S | Yes | 1 |
| g6e.8xlarge | 4.52856 USD/hour | NVIDIA L40S | Yes | 1 |
| g6e.12xlarge | 10.49264 USD/hour | NVIDIA L40S | Yes | 4 |
| g6e.16xlarge | 7.57719 USD/hour | NVIDIA L40S | Yes | 1 |
| g6e.24xlarge | 15.06559 USD/hour | NVIDIA L40S | Yes | 4 |
| g6e.48xlarge | 30.13118 USD/hour | NVIDIA L40S | Yes | 8 |
| g6.xlarge | 0.8048 USD/hour | NVIDIA L4 | Yes | 1 |
| g6.2xlarge | 0.9776 USD/hour | NVIDIA L4 | Yes | 1 |
| g6.4xlarge | 1.3232 USD/hour | NVIDIA L4 | Yes | 1 |
| g6.8xlarge | 2.0144 USD/hour | NVIDIA L4 | Yes | 1 |
| g6.12xlarge | 4.6016 USD/hour | NVIDIA L4 | Yes | 4 |
| g6.16xlarge | 3.3968 USD/hour | NVIDIA L4 | Yes | 1 |
| g6.24xlarge | 6.6752 USD/hour | NVIDIA L4 | Yes | 4 |
| g6.48xlarge | 13.3504 USD/hour | NVIDIA L4 | Yes | 8 |
| g5.xlarge | 1.006 USD/hour | NVIDIA A10G | Yes | 1 |
| g5.2xlarge | 1.212 USD/hour | NVIDIA A10G | Yes | 1 |
| g5.4xlarge | 1.624 USD/hour | NVIDIA A10G | Yes | 1 |
| g5.8xlarge | 2.448 USD/hour | NVIDIA A10G | Yes | 1 |
| g5.12xlarge | 5.672 USD/hour | NVIDIA A10G | Yes | 4 |
| g5.16xlarge | 4.096 USD/hour | NVIDIA A10G | Yes | 1 |
| g5.24xlarge | 8.144 USD/hour | NVIDIA A10G | Yes | 4 |
| g5.48xlarge | 16.288 USD/hour | NVIDIA A10G | Yes | 8 |
| g4dn.xlarge | 0.526 USD/hour | NVIDIA T4 | Yes | 1 |
| g4dn.2xlarge | 0.752 USD/hour | NVIDIA T4 | Yes | 1 |
| g4dn.4xlarge | 1.204 USD/hour | NVIDIA T4 | Yes | 1 |
| g4dn.8xlarge | 2.176 USD/hour | NVIDIA T4 | Yes | 1 |
| g4dn.12xlarge | 3.912 USD/hour | NVIDIA T4 | Yes | 4 |
| g4dn.16xlarge | 4.352 USD/hour | NVIDIA T4 | Yes | 1 |
| g4dn.metal | 7.824 USD/hour | NVIDIA T4 | Yes | 8 |
| g4ad.xlarge | 0.37853 USD/hour | AMD Radeon Pro V520 | No | 1 |
| g4ad.2xlarge | 0.54117 USD/hour | AMD Radeon Pro V520 | No | 1 |
| g4ad.4xlarge | 0.867 USD/hour | AMD Radeon Pro V520 | No | 1 |
| g4ad.8xlarge | 1.734 USD/hour | AMD Radeon Pro V520 | No | 2 |
| g4ad.16xlarge | 3.468 USD/hour | AMD Radeon Pro V520 | No | 4 |

## One-GPU Instances Only

| Instance type | On-demand Linux price | GPU name | GPU supports RT | GPU memory |
|---|---:|---|---|---:|
| p5.4xlarge | 6.88 USD/hour | NVIDIA H100 | No | 80 GiB |
| gr6.4xlarge | 1.5392 USD/hour | NVIDIA L4 | Yes | 22 GiB |
| gr6.8xlarge | 2.4464 USD/hour | NVIDIA L4 | Yes | 22 GiB |
| g7e.2xlarge | 3.36312 USD/hour | NVIDIA RTX PRO Server 6000 | Yes | 96 GiB |
| g7e.4xlarge | 3.99816 USD/hour | NVIDIA RTX PRO Server 6000 | Yes | 96 GiB |
| g7e.8xlarge | 5.26824 USD/hour | NVIDIA RTX PRO Server 6000 | Yes | 96 GiB |
| g6e.xlarge | 1.861 USD/hour | NVIDIA L40S | Yes | 44 GiB |
| g6e.2xlarge | 2.24208 USD/hour | NVIDIA L40S | Yes | 44 GiB |
| g6e.4xlarge | 3.00424 USD/hour | NVIDIA L40S | Yes | 44 GiB |
| g6e.8xlarge | 4.52856 USD/hour | NVIDIA L40S | Yes | 44 GiB |
| g6e.16xlarge | 7.57719 USD/hour | NVIDIA L40S | Yes | 44 GiB |
| g6.xlarge | 0.8048 USD/hour | NVIDIA L4 | Yes | 22 GiB |
| g6.2xlarge | 0.9776 USD/hour | NVIDIA L4 | Yes | 22 GiB |
| g6.4xlarge | 1.3232 USD/hour | NVIDIA L4 | Yes | 22 GiB |
| g6.8xlarge | 2.0144 USD/hour | NVIDIA L4 | Yes | 22 GiB |
| g6.16xlarge | 3.3968 USD/hour | NVIDIA L4 | Yes | 22 GiB |
| g5.xlarge | 1.006 USD/hour | NVIDIA A10G | Yes | 22 GiB |
| g5.2xlarge | 1.212 USD/hour | NVIDIA A10G | Yes | 22 GiB |
| g5.4xlarge | 1.624 USD/hour | NVIDIA A10G | Yes | 22 GiB |
| g5.8xlarge | 2.448 USD/hour | NVIDIA A10G | Yes | 22 GiB |
| g5.16xlarge | 4.096 USD/hour | NVIDIA A10G | Yes | 22 GiB |
| g4dn.xlarge | 0.526 USD/hour | NVIDIA T4 | Yes | 16 GiB |
| g4dn.2xlarge | 0.752 USD/hour | NVIDIA T4 | Yes | 16 GiB |
| g4dn.4xlarge | 1.204 USD/hour | NVIDIA T4 | Yes | 16 GiB |
| g4dn.8xlarge | 2.176 USD/hour | NVIDIA T4 | Yes | 16 GiB |
| g4dn.16xlarge | 4.352 USD/hour | NVIDIA T4 | Yes | 16 GiB |
| g4ad.xlarge | 0.37853 USD/hour | AMD Radeon Pro V520 | No | 8 GiB |
| g4ad.2xlarge | 0.54117 USD/hour | AMD Radeon Pro V520 | No | 8 GiB |
| g4ad.4xlarge | 0.867 USD/hour | AMD Radeon Pro V520 | No | 8 GiB |

## Low-CPU One-GPU RT-Capable Instances

These are the smallest entries from the one-GPU table that also have dedicated
RT hardware. The main preference is `xlarge` to avoid paying for extra CPU and
memory capacity when the goal is to get one RT-capable GPU at the lowest
instance size. `g7e.2xlarge` is included as the smallest one-GPU `g7e` option,
even though it is larger than `xlarge`.

| Instance type | On-demand Linux price | GPU name | GPU memory |
|---|---:|---|---:|
| g4dn.xlarge | 0.526 USD/hour | NVIDIA T4 | 16 GiB |
| g6.xlarge | 0.8048 USD/hour | NVIDIA L4 | 22 GiB |
| g5.xlarge | 1.006 USD/hour | NVIDIA A10G | 22 GiB |
| g6e.xlarge | 1.861 USD/hour | NVIDIA L40S | 44 GiB |
| g7e.2xlarge | 3.36312 USD/hour | NVIDIA RTX PRO Server 6000 | 96 GiB |

## Notes

- P-series instances here use NVIDIA data-center compute GPUs. They are strong
  for tensor/HPC workloads, but they do not expose dedicated RT cores like RTX,
  L4, L40S, A10G, or T4 class GPUs.
- G-series instances are more relevant for hardware-accelerated graphics and RT
  workloads. In this list, `g4dn`, `g5`, `g6`, `gr6`, `g6e`, and `g7e` are the
  RT-capable NVIDIA families.
- `g4ad` uses AMD Radeon Pro V520. It can run graphics workloads, but it is not
  treated here as a dedicated hardware RT instance family.
- `p5e.48xlarge` appears in the screenshot with no visible on-demand Linux
  price, so the price is recorded as `-`.

## References

- AWS EC2 accelerated-computing instance specifications:
  <https://docs.aws.amazon.com/ec2/latest/instancetypes/ac.html>
- NVIDIA A10 product page, listing RT cores:
  <https://www.nvidia.com/en-us/data-center/products/a10-gpu/>
- NVIDIA L4 product page, describing third-generation RT cores:
  <https://www.nvidia.com/en-au/data-center/l4/>
- NVIDIA L40S product page, describing third-generation RT cores:
  <https://www.nvidia.com/en-us/data-center/l40s/>
- NVIDIA Turing architecture notes, describing RT cores in Turing GPUs:
  <https://developer.nvidia.com/blog/nvidia-turing-architecture-in-depth/>
