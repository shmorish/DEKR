#!/bin/bash

# check conda env
source ~/anaconda3/etc/profile.d/conda.sh
conda activate hrnet

BLUE='\033[0;34m'
NC='\033[0m'

config="experiments/coco/inference_demo_coco.yaml"
model="model/pose_coco/pose_dekr_hrnetw32_coco.pth"

end_count=$(ls -1 ~/nturgbd_rgb_dataset/ | wc -l)
current_count=0

# signal handler
function signal_handler() {
    echo "error"
    exit 1
}
trap signal_handler 2

retry_interval=3
function inference() {
    while true; do
        python3 tools/inference_demo.py --cfg ${config} --videoFile $1 --outputDir output --visthre 0.1 TEST.MODEL_FILE ${model}
        if [ $? -eq 0 ]; then
            break
        fi
        echo -e "${BLUE}Retry $1${NC}"
        sleep $retry_interval
    done
}

max_jobs=2
job_count=0

result_path_dir="output/data/"

for file in ~/nturgbd_rgb_dataset/*.avi
do
    result_path=$result_path_dir$(basename $file) 
    result_path="${result_path%.*}.csv"
    if [ -f $result_path ]; then
        echo -e "${BLUE}Skip $file${NC}"
        current_count=$((current_count+1))
        continue
    fi
    echo "Processing $file"
    inference $file &
    job_count=$((job_count+1))
    if [ $job_count -ge $max_jobs ]; then
        wait -n
        job_count=$((job_count-1))
    fi
    current_count=$((current_count+1))
    percent=$((current_count*100/end_count))
    echo -e "${BLUE}Done $current_count/$end_count ($percent%)${NC}"
done