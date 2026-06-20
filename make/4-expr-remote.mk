REMOTE_REPO_DIR ?= /home/ubuntu/XBlossom-SIGMETRICS27-AE
REMOTE_CPU_HOST ?= aws-cpu
REMOTE_GPU_HOST ?= aws-gpu

.PHONY: remote-perf-list remote-gpu-counters remote-all remote-1_graph_metrics remote-2_reuse remote-3_load_balance remote-4_xb_pro_inst remote-5_runtime remote-6_inst_rate remote-7_memory remote-8_runtime_four remote-9_inst_rate_four remote-10_memory_four remote-11_throughput remote-12_runtime_four_bbss remote-13_inst_rate_four_bbss remote-14_memory_four_bbss remote-15_throughput_bbss remote-16_scalability_test

remote-perf-list:
	./scripts/4-expr-remote/fetch_perf_list.sh

remote-gpu-counters:
	./scripts/4-expr-remote/fetch_gpu_counters.sh

define run_cpu
	ssh $(REMOTE_CPU_HOST) "cd $(REMOTE_REPO_DIR) && ./scripts/4-expr/$(1)"
endef

define run_gpu
	ssh $(REMOTE_GPU_HOST) "cd $(REMOTE_REPO_DIR) && ./scripts/4-expr/$(1)"
endef

define fetch_cpu
	mkdir -p results/$(1) tmp/$(1)
	rsync -a $(REMOTE_CPU_HOST):$(REMOTE_REPO_DIR)/results/$(1)/ results/$(1)/
	rsync -a $(REMOTE_CPU_HOST):$(REMOTE_REPO_DIR)/tmp/$(1)/ tmp/$(1)/
endef

define fetch_gpu
	mkdir -p results/$(1) tmp/$(1)
	rsync -a $(REMOTE_GPU_HOST):$(REMOTE_REPO_DIR)/results/$(1)/ results/$(1)/
	rsync -a $(REMOTE_GPU_HOST):$(REMOTE_REPO_DIR)/tmp/$(1)/ tmp/$(1)/
endef

remote-all: remote-1_graph_metrics remote-2_reuse remote-3_load_balance remote-4_xb_pro_inst remote-5_runtime remote-6_inst_rate remote-7_memory remote-8_runtime_four remote-9_inst_rate_four remote-10_memory_four remote-11_throughput remote-12_runtime_four_bbss remote-13_inst_rate_four_bbss remote-14_memory_four_bbss remote-15_throughput_bbss remote-16_scalability_test

remote-1_graph_metrics: remote-build-gpu remote-datasets-gpu prepare_logs
	$(call run_gpu,1_graph_metrics/RUN_graph_metrics.sh)
	$(call fetch_gpu,1_graph_metrics)
	./scripts/4-expr/1_graph_metrics/generate_table_csv.sh
	./scripts/4-expr/1_graph_metrics/generate_table_1_tex.sh

remote-2_reuse: remote-build-cpu remote-build-gpu remote-datasets-cpu remote-datasets-gpu prepare_logs
	mkdir -p tmp/2_reuse
	(ssh $(REMOTE_CPU_HOST) "cd $(REMOTE_REPO_DIR) && ./scripts/4-expr/2_reuse/RUN_xb_and_xb_pro.sh" > tmp/2_reuse/remote_cpu.log 2>&1) & cpu_pid=$$!; \
	(ssh $(REMOTE_GPU_HOST) "cd $(REMOTE_REPO_DIR) && ./scripts/4-expr/2_reuse/RUN_xb_pp_r_nr.sh" > tmp/2_reuse/remote_gpu.log 2>&1) & gpu_pid=$$!; \
	wait $$cpu_pid; cpu_status=$$?; \
	wait $$gpu_pid; gpu_status=$$?; \
	if [ $$cpu_status -ne 0 ] || [ $$gpu_status -ne 0 ]; then \
	  echo "remote-2_reuse failed. See tmp/2_reuse/remote_cpu.log and tmp/2_reuse/remote_gpu.log"; \
	  exit 1; \
	fi
	$(call fetch_cpu,2_reuse)
	$(call fetch_gpu,2_reuse)
	./scripts/4-expr/2_reuse/generate_table_cpu.sh
	./scripts/4-expr/2_reuse/generate_table_gpu.sh
	./scripts/4-expr/2_reuse/generate_table_2_tex.sh

remote-3_load_balance: remote-build-cpu remote-build-gpu remote-datasets-cpu remote-datasets-gpu prepare_logs
	mkdir -p tmp/3_load_balance
	(ssh $(REMOTE_CPU_HOST) "cd $(REMOTE_REPO_DIR) && ./scripts/4-expr/3_load_balance/run_cpu_loadbalance_all_datasets.sh" > tmp/3_load_balance/remote_cpu.log 2>&1) & cpu_pid=$$!; \
	(ssh $(REMOTE_GPU_HOST) "cd $(REMOTE_REPO_DIR) && ./scripts/4-expr/3_load_balance/run_gpu_loadbalance_all_datasets.sh" > tmp/3_load_balance/remote_gpu.log 2>&1) & gpu_pid=$$!; \
	wait $$cpu_pid; cpu_status=$$?; \
	wait $$gpu_pid; gpu_status=$$?; \
	if [ $$cpu_status -ne 0 ] || [ $$gpu_status -ne 0 ]; then \
	  echo "remote-3_load_balance failed. See tmp/3_load_balance/remote_cpu.log and tmp/3_load_balance/remote_gpu.log"; \
	  exit 1; \
	fi
	$(call fetch_cpu,3_load_balance)
	$(call fetch_gpu,3_load_balance)
	./scripts/4-expr/3_load_balance/generate_table_cpu.sh
	./scripts/4-expr/3_load_balance/generate_table_gpu.sh
	./scripts/4-expr/3_load_balance/generate_table_3_tex.sh

remote-5_runtime: remote-build-cpu remote-build-gpu remote-datasets-cpu remote-datasets-gpu prepare_logs
	$(call run_cpu,5_runtime/RUN_xb_pro_time.sh)
	$(call run_gpu,5_runtime/RUN_xb_pp_time.sh)
	$(call run_cpu,5_runtime/RUN_bfs_ligra_time.sh)
	$(call run_gpu,5_runtime/RUN_bfs_gunrock_time.sh)
	$(call fetch_cpu,5_runtime)
	$(call fetch_gpu,5_runtime)
	./scripts/4-expr/5_runtime/plot_figure_6.sh

remote-6_inst_rate: remote-build-cpu remote-build-gpu remote-datasets-cpu remote-datasets-gpu prepare_logs
	$(call run_cpu,6_inst_rate/RUN_xb_pro_inst.sh)
	$(call run_cpu,6_inst_rate/RUN_bfs_ligra_inst.sh)
	$(call run_gpu,6_inst_rate/RUN_xb_pp_inst.sh)
	$(call run_gpu,6_inst_rate/RUN_bfs_gunrock_inst.sh)
	$(call fetch_cpu,6_inst_rate)
	$(call fetch_gpu,6_inst_rate)
	./scripts/4-expr/6_inst_rate/generate_table_5.sh

remote-4_xb_pro_inst: remote-build-cpu remote-datasets-cpu prepare_logs
	$(call run_cpu,4_xb_pro_inst/RUN_xb_pro_inst_node.sh)
	$(call run_cpu,4_xb_pro_inst/RUN_xb_pro_inst_edge.sh)
	$(call fetch_cpu,4_xb_pro_inst)
	./scripts/4-expr/4_xb_pro_inst/plot_figure_7.sh
	./scripts/4-expr/4_xb_pro_inst/generate_table_6.sh

remote-7_memory: remote-build-cpu remote-build-gpu remote-datasets-cpu remote-datasets-gpu prepare_logs
	$(call run_cpu,7_memory/RUN_xb_pro_mem.sh)
	$(call run_cpu,7_memory/RUN_bfs_ligra_mem.sh)
	$(call run_gpu,7_memory/RUN_xb_pp_mem.sh)
	$(call run_gpu,7_memory/RUN_bfs_gunrock_mem.sh)
	$(call fetch_cpu,7_memory)
	$(call fetch_gpu,7_memory)
	./scripts/4-expr/7_memory/generate_table_6.sh

remote-8_runtime_four: remote-build-cpu remote-build-gpu remote-datasets-cpu remote-datasets-gpu prepare_logs
	$(call run_cpu,8_runtime_four/RUN_xb_pro_time.sh)
	$(call run_gpu,8_runtime_four/RUN_xb_pp_time.sh)
	$(call run_cpu,8_runtime_four/RUN_bfs_ligra_time.sh)
	$(call run_cpu,8_runtime_four/RUN_bc_ligra_time.sh)
	$(call run_cpu,8_runtime_four/RUN_sssp_ligra_time.sh)
	$(call run_cpu,8_runtime_four/RUN_multisssp_ligra_time.sh)
	$(call run_gpu,8_runtime_four/RUN_bfs_gunrock_time.sh)
	$(call run_gpu,8_runtime_four/RUN_bc_gunrock_time.sh)
	$(call run_gpu,8_runtime_four/RUN_sssp_gunrock_time.sh)
	$(call fetch_cpu,8_runtime_four)
	$(call fetch_gpu,8_runtime_four)
	./scripts/4-expr/8_runtime_four/plot_figure_8.sh
	./scripts/4-expr/8_runtime_four/generate_runtime_ci_tables.sh

remote-9_inst_rate_four: remote-build-cpu remote-build-gpu remote-datasets-cpu remote-datasets-gpu prepare_logs
	$(call run_cpu,9_inst_rate_four/RUN_xb_pro_inst.sh)
	$(call run_cpu,9_inst_rate_four/RUN_bfs_ligra_inst.sh)
	$(call run_cpu,9_inst_rate_four/RUN_bc_ligra_inst.sh)
	$(call run_cpu,9_inst_rate_four/RUN_sssp_ligra_inst.sh)
	$(call run_gpu,9_inst_rate_four/RUN_xb_pp_inst.sh)
	$(call run_gpu,9_inst_rate_four/RUN_bfs_gunrock_inst.sh)
	$(call run_gpu,9_inst_rate_four/RUN_bc_gunrock_inst.sh)
	$(call run_gpu,9_inst_rate_four/RUN_sssp_gunrock_inst.sh)
	$(call fetch_cpu,9_inst_rate_four)
	$(call fetch_gpu,9_inst_rate_four)
	./scripts/4-expr/9_inst_rate_four/generate_table_9.sh

remote-10_memory_four: remote-build-cpu remote-build-gpu remote-datasets-cpu remote-datasets-gpu prepare_logs
	$(call run_cpu,10_memory_four/RUN_xb_pro_mem.sh)
	$(call run_cpu,10_memory_four/RUN_bfs_ligra_mem.sh)
	$(call run_cpu,10_memory_four/RUN_bc_ligra_mem.sh)
	$(call run_cpu,10_memory_four/RUN_sssp_ligra_mem.sh)
	$(call run_gpu,10_memory_four/RUN_xb_pp_mem.sh)
	$(call run_gpu,10_memory_four/RUN_bfs_gunrock_mem.sh)
	$(call run_gpu,10_memory_four/RUN_bc_gunrock_mem.sh)
	$(call run_gpu,10_memory_four/RUN_sssp_gunrock_mem.sh)
	$(call fetch_cpu,10_memory_four)
	$(call fetch_gpu,10_memory_four)
	./scripts/4-expr/10_memory_four/generate_table_10.sh

remote-11_throughput: remote-build-cpu remote-build-gpu remote-datasets-cpu remote-datasets-gpu prepare_logs
	$(call run_cpu,11_throughput/RUN_xb_pro_throughput.sh)
	$(call run_cpu,11_throughput/RUN_bfs_ligra_throughput.sh)
	$(call run_cpu,11_throughput/RUN_bc_ligra_throughput.sh)
	$(call run_cpu,11_throughput/RUN_sssp_ligra_throughput.sh)
	$(call run_gpu,11_throughput/RUN_xb_pp_throughput.sh)
	$(call run_gpu,11_throughput/RUN_bfs_gunrock_throughput.sh)
	$(call run_gpu,11_throughput/RUN_bc_gunrock_throughput.sh)
	$(call run_gpu,11_throughput/RUN_sssp_gunrock_throughput.sh)
	$(call fetch_cpu,11_throughput)
	$(call fetch_gpu,11_throughput)
	./scripts/4-expr/11_throughput/generate_table_11.sh

remote-12_runtime_four_bbss: remote-build-cpu remote-build-gpu remote-datasets-cpu remote-datasets-gpu prepare_logs
	$(call run_cpu,12_runtime_four_bbss/RUN_xb_pro_time.sh)
	$(call run_gpu,12_runtime_four_bbss/RUN_xb_pp_time.sh)
	$(call run_cpu,12_runtime_four_bbss/RUN_bfs_ligra_time.sh)
	$(call run_cpu,12_runtime_four_bbss/RUN_multisssp_ligra_time.sh)
	$(call run_cpu,12_runtime_four_bbss/RUN_sssp_ligra_time.sh)
	$(call run_gpu,12_runtime_four_bbss/RUN_bfs_gunrock_time.sh)
	$(call run_gpu,12_runtime_four_bbss/RUN_multisssp_gunrock_time.sh)
	$(call run_gpu,12_runtime_four_bbss/RUN_sssp_gunrock_time.sh)
	$(call fetch_cpu,12_runtime_four_bbss)
	$(call fetch_gpu,12_runtime_four_bbss)
	./scripts/4-expr/12_runtime_four_bbss/plot_figure_12.sh
	./scripts/4-expr/12_runtime_four_bbss/generate_table_12.sh

remote-13_inst_rate_four_bbss: remote-build-cpu remote-build-gpu remote-datasets-cpu remote-datasets-gpu prepare_logs
	$(call run_cpu,13_inst_rate_four_bbss/RUN_xb_pro_inst.sh)
	$(call run_cpu,13_inst_rate_four_bbss/RUN_bfs_ligra_inst.sh)
	$(call run_cpu,13_inst_rate_four_bbss/RUN_multisssp_ligra_inst.sh)
	$(call run_cpu,13_inst_rate_four_bbss/RUN_sssp_ligra_inst.sh)
	$(call run_gpu,13_inst_rate_four_bbss/RUN_xb_pp_inst.sh)
	$(call run_gpu,13_inst_rate_four_bbss/RUN_bfs_gunrock_inst.sh)
	$(call run_gpu,13_inst_rate_four_bbss/RUN_multisssp_gunrock_inst.sh)
	$(call run_gpu,13_inst_rate_four_bbss/RUN_sssp_gunrock_inst.sh)
	$(call fetch_cpu,13_inst_rate_four_bbss)
	$(call fetch_gpu,13_inst_rate_four_bbss)
	./scripts/4-expr/13_inst_rate_four_bbss/generate_table_13.sh

remote-14_memory_four_bbss: remote-build-cpu remote-build-gpu remote-datasets-cpu remote-datasets-gpu prepare_logs
	$(call run_cpu,14_memory_four_bbss/RUN_xb_pro_mem.sh)
	$(call run_cpu,14_memory_four_bbss/RUN_bfs_ligra_mem.sh)
	$(call run_cpu,14_memory_four_bbss/RUN_multisssp_ligra_mem.sh)
	$(call run_cpu,14_memory_four_bbss/RUN_sssp_ligra_mem.sh)
	$(call run_gpu,14_memory_four_bbss/RUN_xb_pp_mem.sh)
	$(call run_gpu,14_memory_four_bbss/RUN_bfs_gunrock_mem.sh)
	$(call run_gpu,14_memory_four_bbss/RUN_multisssp_gunrock_mem.sh)
	$(call run_gpu,14_memory_four_bbss/RUN_sssp_gunrock_mem.sh)
	$(call fetch_cpu,14_memory_four_bbss)
	$(call fetch_gpu,14_memory_four_bbss)
	./scripts/4-expr/14_memory_four_bbss/generate_table_14.sh

remote-15_throughput_bbss: remote-build-cpu remote-build-gpu remote-datasets-cpu remote-datasets-gpu prepare_logs
	$(call run_cpu,15_throughput_bbss/RUN_xb_pro_throughput.sh)
	$(call run_cpu,15_throughput_bbss/RUN_bfs_ligra_throughput.sh)
	$(call run_cpu,15_throughput_bbss/RUN_multisssp_ligra_throughput.sh)
	$(call run_cpu,15_throughput_bbss/RUN_sssp_ligra_throughput.sh)
	$(call run_gpu,15_throughput_bbss/RUN_xb_pp_throughput.sh)
	$(call run_gpu,15_throughput_bbss/RUN_bfs_gunrock_throughput.sh)
	$(call run_gpu,15_throughput_bbss/RUN_multisssp_gunrock_throughput.sh)
	$(call run_gpu,15_throughput_bbss/RUN_sssp_gunrock_throughput.sh)
	$(call fetch_cpu,15_throughput_bbss)
	$(call fetch_gpu,15_throughput_bbss)
	./scripts/4-expr/15_throughput_bbss/generate_table_15.sh
	./scripts/4-expr/15_throughput_bbss/generate_runtime_table_15.sh
	./scripts/4-expr/15_throughput_bbss/plot_figure_15.sh

remote-16_scalability_test: remote-build-cpu remote-build-gpu remote-datasets-cpu remote-datasets-gpu prepare_logs
	$(call run_cpu,16_scalability_test/RUN_xb_pro_node_cpu.sh)
	$(call run_cpu,16_scalability_test/RUN_xb_pro_edge_cpu.sh)
	$(call run_gpu,16_scalability_test/RUN_xb_pp_node_gpu_sm.sh)
	$(call run_gpu,16_scalability_test/RUN_xb_pp_edge_gpu_sm.sh)
	$(call fetch_cpu,16_scalability_test)
	$(call fetch_gpu,16_scalability_test)
	./scripts/4-expr/16_scalability_test/plot_scalability.sh
	./scripts/4-expr/16_scalability_test/generate_table_xb_pro_node_cpu.sh
	./scripts/4-expr/16_scalability_test/generate_table_xb_pro_edge_cpu.sh
	./scripts/4-expr/16_scalability_test/generate_table_xb_pp_node_gpu_sm.sh
	./scripts/4-expr/16_scalability_test/generate_table_xb_pp_edge_gpu_sm.sh
