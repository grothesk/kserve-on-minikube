#!/bin/sh

model_name="$1" && shift && test -n "$model_name" &&
file_list=$(find "$model_name"/artifacts -maxdepth 1 -type f -printf "%p," | sed 's/,$//') &&
torch-model-archiver --handler "$model_name"/handler.py --model-name "$model_name" --config-file "$model_name"/model-config.yaml --version 1.0 --extra-files "$file_list",torchserve_handler.py --requirements-file "$model_name"/requirements.txt $@
