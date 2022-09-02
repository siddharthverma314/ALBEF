#!/bin/bash
#SBATCH --nodes=1
##SBATCH --partition=hipri
#SBATCH --tasks-per-node=1
#SBATCH --gpus-per-task=8
#SBATCH --cpus-per-task=96

# srun /data/home/siddharthverma/setup direnv exec $PWD \
     python -m torch.distributed.launch \
     --nproc_per_node=8 \
     --use_env Pretrain.py \
     --config ./configs/Pretrain.yaml \
     --output_dir output/Pretrain
