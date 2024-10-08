DATA_ROOT=/mnt/cluster/wym/SuperGLUE
CHECKPOINT_PATH=/mnt/cluster/wym/glm-10b-chinese_bak
SAVE_PATH=/workspace/GLM/output/save_path
DATESTR=$(date +"%m-%d-%H-%M")

source $1    # Model
source $2    # Task


NUM_WORKERS=2
NUM_GPUS_PER_WORKER=4
HOST_FILE_PATH="./hostfile"
MP_SIZE=2
MASTER_PORT=$(shuf -n 1 -i 10000-65535)

OPTIONS_NCCL="NCCL_DEBUG=info NCCL_IB_DISABLE=0 NCCL_NET_GDR_LEVEL=2"
DISTRIBUTED_ARGS="${OPTIONS_NCCL} deepspeed --hostfile ${HOST_FILE_PATH} --master_port $MASTER_PORT --num_nodes ${NUM_WORKERS} --num_gpus ${NUM_GPUS_PER_WORKER}"

EXPERIMENT_NAME=${EXPERIMENT_NAME}_${DATESTR}
mkdir logs
run_cmd="${DISTRIBUTED_ARGS} finetune_glm.py \
       --deepspeed \
       --deepspeed_config config_tasks/config_blocklm_10B.json \
       --finetune \
       --cloze-eval \
       --experiment-name ${EXPERIMENT_NAME} \
       --task ${TASK_NAME} \
       --data-dir ${DATA_PATH} \
       --save ${CHECKPOINT_PATH} \
       --seq-length ${MAX_SEQ_LEN} \
       --checkpoint-activations \
       --eval-batch-size 16 \
       --save-epoch 100000 \
       --num-workers 2 \
       --no-load-optim \
       --no-load-lr-scheduler \
       $MODEL_ARGS \
       $TRAIN_ARGS \
       $COMMON_ARGS \
       --pattern-id 0 \
       --fp16 \
       --model-parallel-size ${MP_SIZE} \
       --epochs ${XXLARGE_EPOCH} \
       --overwrite \
       2>&1 | tee logs/log-${EXPERIMENT_NAME}.txt"

echo ${run_cmd}
eval ${run_cmd}