#!/bin/bash
curl -LJO ${URL}
mv ${FILE} ${TARGET_DIR}/
kubectl apply -f ${TARGET_DIR}/${FILE}
