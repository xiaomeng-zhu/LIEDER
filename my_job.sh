#!/bin/sh

#SBATCH --job-name=my_job
#SBATCH --time=16:00:00
#SBATCH --mail-type=ALL
#SBATCH --partition gpu
#SBATCH --gpus=2
#SBATCH --constraint="a100-80g"

module load miniconda
conda activate the
python scripts/experiments_llama_family_gpu.py config/two_llama3_70B.json