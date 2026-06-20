.PHONY: all update_paper update_paper_tables update_paper_plots 1_graph_metrics 2_reuse 3_load_balance 4_xb_pro_inst 5_runtime 6_runtime_four_bbss 7_inst_rate_four_bbss 8_memory_four_bbss 9_scalability_test

all: 1_graph_metrics 2_reuse 3_load_balance 4_xb_pro_inst 5_runtime 6_runtime_four_bbss 7_inst_rate_four_bbss 8_memory_four_bbss 9_scalability_test

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

4_xb_pro_inst: build process-datasets prepare_logs
	./scripts/4-expr/4_xb_pro_inst/RUN_xb_pro_inst_node.sh
	./scripts/4-expr/4_xb_pro_inst/RUN_xb_pro_inst_edge.sh
	./scripts/4-expr/4_xb_pro_inst/plot_figure_7.sh
	./scripts/4-expr/4_xb_pro_inst/generate_table_6.sh
	$(MAKE) -f make/4-expr-local.mk update_paper_plots

5_runtime: build process-datasets prepare_logs
	./scripts/4-expr/5_runtime/RUN_xb_pro_time.sh
	./scripts/4-expr/5_runtime/RUN_xb_pp_time.sh
	./scripts/4-expr/5_runtime/RUN_bfs_ligra_time.sh
	./scripts/4-expr/5_runtime/RUN_bfs_gunrock_time.sh
	./scripts/4-expr/5_runtime/plot_figure_6.sh

6_runtime_four_bbss: build process-datasets prepare_logs
	./scripts/4-expr/6_runtime_four_bbss/RUN_xb_pro_time.sh
	./scripts/4-expr/6_runtime_four_bbss/RUN_xb_pp_time.sh
	./scripts/4-expr/6_runtime_four_bbss/RUN_bfs_ligra_time.sh
	./scripts/4-expr/6_runtime_four_bbss/RUN_multisssp_ligra_time.sh
	./scripts/4-expr/6_runtime_four_bbss/RUN_sssp_ligra_time.sh
	./scripts/4-expr/6_runtime_four_bbss/RUN_bfs_gunrock_time.sh
	./scripts/4-expr/6_runtime_four_bbss/RUN_multisssp_gunrock_time.sh
	./scripts/4-expr/6_runtime_four_bbss/RUN_sssp_gunrock_time.sh
	./scripts/4-expr/6_runtime_four_bbss/plot_figure_6.sh
	./scripts/4-expr/6_runtime_four_bbss/generate_table_6.sh
	$(MAKE) -f make/4-expr-local.mk update_paper_plots

7_inst_rate_four_bbss: build process-datasets prepare_logs
	./scripts/4-expr/7_inst_rate_four_bbss/RUN_xb_pro_inst.sh
	./scripts/4-expr/7_inst_rate_four_bbss/RUN_bfs_ligra_inst.sh
	./scripts/4-expr/7_inst_rate_four_bbss/RUN_multisssp_ligra_inst.sh
	./scripts/4-expr/7_inst_rate_four_bbss/RUN_sssp_ligra_inst.sh
	./scripts/4-expr/7_inst_rate_four_bbss/RUN_xb_pp_inst.sh
	./scripts/4-expr/7_inst_rate_four_bbss/RUN_bfs_gunrock_inst.sh
	./scripts/4-expr/7_inst_rate_four_bbss/RUN_multisssp_gunrock_inst.sh
	./scripts/4-expr/7_inst_rate_four_bbss/RUN_sssp_gunrock_inst.sh
	./scripts/4-expr/7_inst_rate_four_bbss/generate_table_7.sh

8_memory_four_bbss: build process-datasets prepare_logs
	./scripts/4-expr/8_memory_four_bbss/RUN_xb_pro_mem.sh
	./scripts/4-expr/8_memory_four_bbss/RUN_bfs_ligra_mem.sh
	./scripts/4-expr/8_memory_four_bbss/RUN_multisssp_ligra_mem.sh
	./scripts/4-expr/8_memory_four_bbss/RUN_sssp_ligra_mem.sh
	./scripts/4-expr/8_memory_four_bbss/RUN_xb_pp_mem.sh
	./scripts/4-expr/8_memory_four_bbss/RUN_bfs_gunrock_mem.sh
	./scripts/4-expr/8_memory_four_bbss/RUN_multisssp_gunrock_mem.sh
	./scripts/4-expr/8_memory_four_bbss/RUN_sssp_gunrock_mem.sh
	./scripts/4-expr/8_memory_four_bbss/generate_table_8.sh

9_scalability_test: build process-datasets prepare_logs
	./scripts/4-expr/9_scalability_test/RUN_xb_pro_node_cpu.sh
	./scripts/4-expr/9_scalability_test/RUN_xb_pro_edge_cpu.sh
	./scripts/4-expr/9_scalability_test/RUN_xb_pp_node_gpu_sm.sh
	./scripts/4-expr/9_scalability_test/RUN_xb_pp_edge_gpu_sm.sh
	./scripts/4-expr/9_scalability_test/plot_scalability.sh
	./scripts/4-expr/9_scalability_test/generate_table_xb_pro_node_cpu.sh
	./scripts/4-expr/9_scalability_test/generate_table_xb_pro_edge_cpu.sh
	./scripts/4-expr/9_scalability_test/generate_table_xb_pp_node_gpu_sm.sh
	./scripts/4-expr/9_scalability_test/generate_table_xb_pp_edge_gpu_sm.sh
	$(MAKE) -f make/4-expr-local.mk update_paper_plots
