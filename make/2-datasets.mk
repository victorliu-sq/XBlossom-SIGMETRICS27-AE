.PHONY: datasets process-datasets process-datasets-ligra-w remote-datasets-cpu remote-datasets-gpu remote-datasets-ligra-w-cpu

datasets:
	@echo "Dataset download scripts are not included in this artifact."
	@echo "Download raw graphs from public dataset repositories, place CSR files under data/xb, then run:"
	@echo "  make process-datasets"

process-datasets:
	./scripts/2-datasets/ligra/csr_to_ligra_adj.sh
	./scripts/2-datasets/ligra_w/csr_to_ligra_adj_w.sh
	./scripts/2-datasets/ligra_hyper_w/csr_to_ligra_adj_w.sh
	./scripts/2-datasets/gunrock/csr_to_gunrock_mm.sh
	./scripts/2-datasets/gunrock_w/csr_to_gunrock_mm_w.sh
	./scripts/2-datasets/src_nodes/generate_src_lists.sh

process-datasets-ligra-w:
	./scripts/2-datasets/ligra_w/csr_to_ligra_adj_w.sh

remote-datasets-cpu:
	ssh aws-cpu "cd $(REMOTE_REPO_DIR) && ./scripts/2-datasets/ligra/csr_to_ligra_adj.sh"
	ssh aws-cpu "cd $(REMOTE_REPO_DIR) && ./scripts/2-datasets/ligra_w/csr_to_ligra_adj_w.sh"
	ssh aws-cpu "cd $(REMOTE_REPO_DIR) && ./scripts/2-datasets/ligra_hyper_w/csr_to_ligra_adj_w.sh"
	ssh aws-cpu "cd $(REMOTE_REPO_DIR) && ./scripts/2-datasets/gunrock/csr_to_gunrock_mm.sh"
	ssh aws-cpu "cd $(REMOTE_REPO_DIR) && ./scripts/2-datasets/gunrock_w/csr_to_gunrock_mm_w.sh"
	ssh aws-cpu "cd $(REMOTE_REPO_DIR) && ./scripts/2-datasets/src_nodes/generate_src_lists.sh"

remote-datasets-gpu:
	ssh aws-gpu "cd $(REMOTE_REPO_DIR) && ./scripts/2-datasets/ligra/csr_to_ligra_adj.sh"
	ssh aws-gpu "cd $(REMOTE_REPO_DIR) && ./scripts/2-datasets/ligra_w/csr_to_ligra_adj_w.sh"
	ssh aws-gpu "cd $(REMOTE_REPO_DIR) && ./scripts/2-datasets/ligra_hyper_w/csr_to_ligra_adj_w.sh"
	ssh aws-gpu "cd $(REMOTE_REPO_DIR) && ./scripts/2-datasets/gunrock/csr_to_gunrock_mm.sh"
	ssh aws-gpu "cd $(REMOTE_REPO_DIR) && ./scripts/2-datasets/gunrock_w/csr_to_gunrock_mm_w.sh"
	ssh aws-gpu "cd $(REMOTE_REPO_DIR) && ./scripts/2-datasets/src_nodes/generate_src_lists.sh"

remote-datasets-ligra-w-cpu:
	ssh aws-cpu "cd $(REMOTE_REPO_DIR) && ./scripts/2-datasets/ligra_w/csr_to_ligra_adj_w.sh"
