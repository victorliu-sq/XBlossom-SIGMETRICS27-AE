.PHONY: all update_paper update_paper_tables update_paper_plots 1_graph_metrics 2_reuse 3_load_balance 4_xb_pro_inst 5_runtime 6_inst_rate 7_memory 8_runtime_four 9_inst_rate_four 10_memory_four 11_throughput 12_runtime_four_bbss 13_inst_rate_four_bbss 14_memory_four_bbss 15_throughput_bbss 16_scalability_test

all: 1_graph_metrics 2_reuse 3_load_balance 4_xb_pro_inst 5_runtime 6_inst_rate 7_memory 8_runtime_four 9_inst_rate_four 10_memory_four 11_throughput 12_runtime_four_bbss 13_inst_rate_four_bbss 14_memory_four_bbss 15_throughput_bbss 16_scalability_test

update_paper:
	@echo "Paper sources are not included in this artifact repository."

update_paper_tables:
	@echo "Paper sources are not included in this artifact repository."

update_paper_plots:
	@echo "Paper sources are not included in this artifact repository."


1_graph_metrics: build process-datasets prepare_logs
	./scripts/4-expr/1_graph_metrics/RUN_graph_metrics.sh
	./scripts/4-expr/1_graph_metrics/generate_table_csv.sh
	./scripts/4-expr/1_graph_metrics/generate_table_1_tex.sh

2_reuse: build process-datasets prepare_logs
	./scripts/4-expr/2_reuse/RUN_xb_and_xb_pro.sh
	./scripts/4-expr/2_reuse/RUN_xb_pp_r_nr.sh
	./scripts/4-expr/2_reuse/generate_table_cpu.sh
	./scripts/4-expr/2_reuse/generate_table_gpu.sh
	./scripts/4-expr/2_reuse/generate_table_2_tex.sh

3_load_balance: build process-datasets prepare_logs
	./scripts/4-expr/3_load_balance/run_cpu_loadbalance_all_datasets.sh
	./scripts/4-expr/3_load_balance/run_gpu_loadbalance_all_datasets.sh
	./scripts/4-expr/3_load_balance/generate_table_cpu.sh
	./scripts/4-expr/3_load_balance/generate_table_gpu.sh
	./scripts/4-expr/3_load_balance/generate_table_3_tex.sh
	$(MAKE) -f make/4-expr-local.mk update_paper_plots

5_runtime: build process-datasets prepare_logs
	./scripts/4-expr/5_runtime/RUN_xb_pro_time.sh
	./scripts/4-expr/5_runtime/RUN_xb_pp_time.sh
	./scripts/4-expr/5_runtime/RUN_bfs_ligra_time.sh
	./scripts/4-expr/5_runtime/RUN_bfs_gunrock_time.sh
	./scripts/4-expr/5_runtime/plot_figure_6.sh

6_inst_rate: build process-datasets prepare_logs
	./scripts/4-expr/6_inst_rate/RUN_xb_pro_inst.sh
	./scripts/4-expr/6_inst_rate/RUN_bfs_ligra_inst.sh
	./scripts/4-expr/6_inst_rate/RUN_xb_pp_inst.sh
	./scripts/4-expr/6_inst_rate/RUN_bfs_gunrock_inst.sh
	./scripts/4-expr/6_inst_rate/generate_table_5.sh

4_xb_pro_inst: build process-datasets prepare_logs
	./scripts/4-expr/4_xb_pro_inst/RUN_xb_pro_inst_node.sh
	./scripts/4-expr/4_xb_pro_inst/RUN_xb_pro_inst_edge.sh
	./scripts/4-expr/4_xb_pro_inst/plot_figure_7.sh
	./scripts/4-expr/4_xb_pro_inst/generate_table_6.sh
	$(MAKE) -f make/4-expr-local.mk update_paper_plots

7_memory: build process-datasets prepare_logs
	./scripts/4-expr/7_memory/RUN_xb_pro_mem.sh
	./scripts/4-expr/7_memory/RUN_bfs_ligra_mem.sh
	./scripts/4-expr/7_memory/RUN_xb_pp_mem.sh
	./scripts/4-expr/7_memory/RUN_bfs_gunrock_mem.sh
	./scripts/4-expr/7_memory/generate_table_6.sh

8_runtime_four: build process-datasets prepare_logs
	./scripts/4-expr/8_runtime_four/RUN_xb_pro_time.sh
	./scripts/4-expr/8_runtime_four/RUN_xb_pp_time.sh
	./scripts/4-expr/8_runtime_four/RUN_bfs_ligra_time.sh
	./scripts/4-expr/8_runtime_four/RUN_bc_ligra_time.sh
	./scripts/4-expr/8_runtime_four/RUN_sssp_ligra_time.sh
	./scripts/4-expr/8_runtime_four/RUN_multisssp_ligra_time.sh
	./scripts/4-expr/8_runtime_four/RUN_bfs_gunrock_time.sh
	./scripts/4-expr/8_runtime_four/RUN_bc_gunrock_time.sh
	./scripts/4-expr/8_runtime_four/RUN_sssp_gunrock_time.sh
	./scripts/4-expr/8_runtime_four/plot_figure_8.sh
	./scripts/4-expr/8_runtime_four/generate_runtime_ci_tables.sh

9_inst_rate_four: build process-datasets prepare_logs
	./scripts/4-expr/9_inst_rate_four/RUN_xb_pro_inst.sh
	./scripts/4-expr/9_inst_rate_four/RUN_bfs_ligra_inst.sh
	./scripts/4-expr/9_inst_rate_four/RUN_bc_ligra_inst.sh
	./scripts/4-expr/9_inst_rate_four/RUN_sssp_ligra_inst.sh
	./scripts/4-expr/9_inst_rate_four/RUN_xb_pp_inst.sh
	./scripts/4-expr/9_inst_rate_four/RUN_bfs_gunrock_inst.sh
	./scripts/4-expr/9_inst_rate_four/RUN_bc_gunrock_inst.sh
	./scripts/4-expr/9_inst_rate_four/RUN_sssp_gunrock_inst.sh
	./scripts/4-expr/9_inst_rate_four/generate_table_9.sh

10_memory_four: build process-datasets prepare_logs
	./scripts/4-expr/10_memory_four/RUN_xb_pro_mem.sh
	./scripts/4-expr/10_memory_four/RUN_bfs_ligra_mem.sh
	./scripts/4-expr/10_memory_four/RUN_bc_ligra_mem.sh
	./scripts/4-expr/10_memory_four/RUN_sssp_ligra_mem.sh
	./scripts/4-expr/10_memory_four/RUN_xb_pp_mem.sh
	./scripts/4-expr/10_memory_four/RUN_bfs_gunrock_mem.sh
	./scripts/4-expr/10_memory_four/RUN_bc_gunrock_mem.sh
	./scripts/4-expr/10_memory_four/RUN_sssp_gunrock_mem.sh
	./scripts/4-expr/10_memory_four/generate_table_10.sh

11_throughput: build process-datasets prepare_logs
	./scripts/4-expr/11_throughput/RUN_xb_pro_throughput.sh
	./scripts/4-expr/11_throughput/RUN_xb_pp_throughput.sh
	./scripts/4-expr/11_throughput/RUN_bfs_ligra_throughput.sh
	./scripts/4-expr/11_throughput/RUN_bfs_gunrock_throughput.sh
	./scripts/4-expr/11_throughput/RUN_bc_ligra_throughput.sh
	./scripts/4-expr/11_throughput/RUN_bc_gunrock_throughput.sh
	./scripts/4-expr/11_throughput/RUN_sssp_ligra_throughput.sh
	./scripts/4-expr/11_throughput/RUN_sssp_gunrock_throughput.sh
	./scripts/4-expr/11_throughput/generate_table_11.sh

12_runtime_four_bbss: build process-datasets prepare_logs
	./scripts/4-expr/12_runtime_four_bbss/RUN_xb_pro_time.sh
	./scripts/4-expr/12_runtime_four_bbss/RUN_xb_pp_time.sh
	./scripts/4-expr/12_runtime_four_bbss/RUN_bfs_ligra_time.sh
	./scripts/4-expr/12_runtime_four_bbss/RUN_multisssp_ligra_time.sh
	./scripts/4-expr/12_runtime_four_bbss/RUN_sssp_ligra_time.sh
	./scripts/4-expr/12_runtime_four_bbss/RUN_bfs_gunrock_time.sh
	./scripts/4-expr/12_runtime_four_bbss/RUN_multisssp_gunrock_time.sh
	./scripts/4-expr/12_runtime_four_bbss/RUN_sssp_gunrock_time.sh
	./scripts/4-expr/12_runtime_four_bbss/plot_figure_12.sh
	./scripts/4-expr/12_runtime_four_bbss/generate_table_12.sh
	$(MAKE) -f make/4-expr-local.mk update_paper_plots

13_inst_rate_four_bbss: build process-datasets prepare_logs
	./scripts/4-expr/13_inst_rate_four_bbss/RUN_xb_pro_inst.sh
	./scripts/4-expr/13_inst_rate_four_bbss/RUN_bfs_ligra_inst.sh
	./scripts/4-expr/13_inst_rate_four_bbss/RUN_multisssp_ligra_inst.sh
	./scripts/4-expr/13_inst_rate_four_bbss/RUN_sssp_ligra_inst.sh
	./scripts/4-expr/13_inst_rate_four_bbss/RUN_xb_pp_inst.sh
	./scripts/4-expr/13_inst_rate_four_bbss/RUN_bfs_gunrock_inst.sh
	./scripts/4-expr/13_inst_rate_four_bbss/RUN_multisssp_gunrock_inst.sh
	./scripts/4-expr/13_inst_rate_four_bbss/RUN_sssp_gunrock_inst.sh
	./scripts/4-expr/13_inst_rate_four_bbss/generate_table_13.sh

14_memory_four_bbss: build process-datasets prepare_logs
	./scripts/4-expr/14_memory_four_bbss/RUN_xb_pro_mem.sh
	./scripts/4-expr/14_memory_four_bbss/RUN_bfs_ligra_mem.sh
	./scripts/4-expr/14_memory_four_bbss/RUN_multisssp_ligra_mem.sh
	./scripts/4-expr/14_memory_four_bbss/RUN_sssp_ligra_mem.sh
	./scripts/4-expr/14_memory_four_bbss/RUN_xb_pp_mem.sh
	./scripts/4-expr/14_memory_four_bbss/RUN_bfs_gunrock_mem.sh
	./scripts/4-expr/14_memory_four_bbss/RUN_multisssp_gunrock_mem.sh
	./scripts/4-expr/14_memory_four_bbss/RUN_sssp_gunrock_mem.sh
	./scripts/4-expr/14_memory_four_bbss/generate_table_14.sh

15_throughput_bbss: build process-datasets prepare_logs
	./scripts/4-expr/15_throughput_bbss/RUN_xb_pro_throughput.sh
	./scripts/4-expr/15_throughput_bbss/RUN_xb_pp_throughput.sh
	./scripts/4-expr/15_throughput_bbss/RUN_bfs_ligra_throughput.sh
	./scripts/4-expr/15_throughput_bbss/RUN_bfs_gunrock_throughput.sh
	./scripts/4-expr/15_throughput_bbss/RUN_multisssp_ligra_throughput.sh
	./scripts/4-expr/15_throughput_bbss/RUN_multisssp_gunrock_throughput.sh
	./scripts/4-expr/15_throughput_bbss/RUN_sssp_ligra_throughput.sh
	./scripts/4-expr/15_throughput_bbss/RUN_sssp_gunrock_throughput.sh
	./scripts/4-expr/15_throughput_bbss/generate_table_15.sh
	./scripts/4-expr/15_throughput_bbss/generate_runtime_table_15.sh
	./scripts/4-expr/15_throughput_bbss/plot_figure_15.sh

16_scalability_test: build process-datasets prepare_logs
	./scripts/4-expr/16_scalability_test/RUN_xb_pro_node_cpu.sh
	./scripts/4-expr/16_scalability_test/RUN_xb_pro_edge_cpu.sh
	./scripts/4-expr/16_scalability_test/RUN_xb_pp_node_gpu_sm.sh
	./scripts/4-expr/16_scalability_test/RUN_xb_pp_edge_gpu_sm.sh
	./scripts/4-expr/16_scalability_test/plot_scalability.sh
	./scripts/4-expr/16_scalability_test/generate_table_xb_pro_node_cpu.sh
	./scripts/4-expr/16_scalability_test/generate_table_xb_pro_edge_cpu.sh
	./scripts/4-expr/16_scalability_test/generate_table_xb_pp_node_gpu_sm.sh
	./scripts/4-expr/16_scalability_test/generate_table_xb_pp_edge_gpu_sm.sh
	$(MAKE) -f make/4-expr-local.mk update_paper_plots
