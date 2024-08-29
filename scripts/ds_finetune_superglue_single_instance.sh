DATA_ROOT=/mnt/cluster/wym/SuperGLUE
###
 # @Author: wuyamei wuyamei@baidu.com
 # @Date: 2024-08-29 14:19:52
 # @LastEditors: wuyamei wuyamei@baidu.com
 # @LastEditTime: 2024-08-29 14:20:09
 # @FilePath: /GLM/scripts/ds_finetune_superglue_single_instance.sh
 # @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
### 
CHECKPOINT_PATH=/mnt/cluster/wym/glm-10b-chinese_bak
SAVE_PATH=/workspace/GLM/save_path
DATESTR=$(date +"%m-%d-%H-%M")

source $1    # Model
source $2    # Task

NUM_WORKERS=1
NUM_GPUS_PER_WORKER=4
MP_SIZE=2
MASTER_PORT=$(shuf -n 1 -i 10000-65535)

OPTIONS_NCCL="NCCL_DEBUG=info NCCL_IB_DISABLE=0 NCCL_NET_GDR_LEVEL=2"
DISTRIBUTED_ARGS="${OPTIONS_NCCL} deepspeed --master_port $MASTER_PORT --num_nodes ${NUM_WORKERS} --num_gpus ${NUM_GPUS_PER_WORKER}"

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
       --num-workers 1 \
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
