.PHONY: datasets process-datasets process-datasets-ligra-w

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
