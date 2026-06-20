.PHONY: datasets datasets-ligra-w download remote-datasets-cpu remote-datasets-gpu remote-datasets-ligra-w-cpu

datasets:
	./scripts/2-datasets/xb/download_datasets.sh
	./scripts/2-datasets/ligra/download_datasets.sh
	./scripts/2-datasets/ligra_w/download_datasets.sh
	./scripts/2-datasets/gunrock/download_datasets.sh
	./scripts/2-datasets/gunrock_w/download_datasets.sh
	./scripts/2-datasets/src_nodes/generate_src_lists.sh

datasets-ligra-w:
	./scripts/2-datasets/ligra_w/download_datasets.sh

remote-datasets-cpu:
	ssh aws-cpu "cd /home/ubuntu/GACGE && ./scripts/2-datasets/xb/download_datasets.sh"
	ssh aws-cpu "cd /home/ubuntu/GACGE && ./scripts/2-datasets/ligra/download_datasets.sh"
	ssh aws-cpu "cd /home/ubuntu/GACGE && ./scripts/2-datasets/ligra_w/download_datasets.sh"
	ssh aws-cpu "cd /home/ubuntu/GACGE && ./scripts/2-datasets/gunrock/download_datasets.sh"
	ssh aws-cpu "cd /home/ubuntu/GACGE && ./scripts/2-datasets/gunrock_w/download_datasets.sh"
	ssh aws-cpu "cd /home/ubuntu/GACGE && ./scripts/2-datasets/src_nodes/generate_src_lists.sh"

remote-datasets-gpu:
	ssh aws-gpu "cd /home/ubuntu/GACGE && ./scripts/2-datasets/xb/download_datasets.sh"
	ssh aws-gpu "cd /home/ubuntu/GACGE && ./scripts/2-datasets/ligra/download_datasets.sh"
	ssh aws-gpu "cd /home/ubuntu/GACGE && ./scripts/2-datasets/ligra_w/download_datasets.sh"
	ssh aws-gpu "cd /home/ubuntu/GACGE && ./scripts/2-datasets/gunrock/download_datasets.sh"
	ssh aws-gpu "cd /home/ubuntu/GACGE && ./scripts/2-datasets/gunrock_w/download_datasets.sh"
	ssh aws-gpu "cd /home/ubuntu/GACGE && ./scripts/2-datasets/src_nodes/generate_src_lists.sh"

remote-datasets-ligra-w-cpu:
	ssh aws-cpu "cd /home/ubuntu/GACGE && ./scripts/2-datasets/ligra_w/download_datasets.sh"
