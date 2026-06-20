#!/usr/bin/env python3
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

import scalability_table_common as common


TABLES = [
    {
        "key": "xb_pro_node_cpu",
        "title": "XB-Pro node-level CPU scalability",
        "config_label": "CPU thread counts",
        "prefix": "xb_pro_node",
        "suffix": "t",
        "config_arg": "thread_configs",
    },
    {
        "key": "xb_pro_edge_cpu",
        "title": "XB-Pro edge-level CPU scalability",
        "config_label": "CPU thread counts",
        "prefix": "xb_pro_edge",
        "suffix": "t",
        "config_arg": "thread_configs",
    },
    {
        "key": "xb_pp_node_gpu_sm",
        "title": "XB++ node-level GPU scalability",
        "config_label": "maximum GPU SM counts",
        "prefix": "xb_pp_node",
        "suffix": "sms",
        "config_arg": "sm_configs",
    },
    {
        "key": "xb_pp_edge_gpu_sm",
        "title": "XB++ edge-level GPU scalability",
        "config_label": "maximum GPU SM counts",
        "prefix": "xb_pp_edge",
        "suffix": "sms",
        "config_arg": "sm_configs",
    },
]


def parse_args():
    parser = argparse.ArgumentParser(description="Generate one TeX file containing all scalability CI tables.")
    parser.add_argument("--metrics-root", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--datasets", nargs="+", required=True)
    parser.add_argument("--thread-configs", nargs="+", required=True)
    parser.add_argument("--sm-configs", nargs="+", required=True)
    return parser.parse_args()


def main():
    args = parse_args()
    tables = []
    for table in TABLES:
        configs = getattr(args, table["config_arg"])
        metrics_dir = os.path.join(args.metrics_root, table["key"])
        rows = common.read_table(
            metrics_dir,
            args.datasets,
            configs,
            table["prefix"],
            table["suffix"],
        )
        output_label_path = os.path.join(os.path.dirname(args.output), f"tab_{table['key']}_scalability_ci.tex")
        tables.append(common.build_tex(rows, configs, output_label_path, table["title"], table["config_label"]))

    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, "w") as f:
        f.write("\n".join(tables))
    print(f"[OK] Wrote {args.output}")


if __name__ == "__main__":
    main()
