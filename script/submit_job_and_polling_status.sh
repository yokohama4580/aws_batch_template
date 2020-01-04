#!/bin/sh -eu
# 引数チェック
if [ $# -ne 1  ]; then
  echo "実行するには引数にaws batchのjob definitionを指定してください。" 1>&2
  exit 1
fi

echo 'TARGET=' ${1}
TARGET=${1}
AWS_BATCH_JOB_QUEUE=enps_optimal_queue

BATCH_JOB_ID=`aws batch submit-job --job-name $TARGET --job-queue $AWS_BATCH_JOB_QUEUE --job-definition $TARGET | jq -r '.jobId'`
if [ -z "$BATCH_JOB_ID" ]; then
  echo "SubmitJob failed" 1>&2
  exit 1
fi
echo 'batch job-id is '$BATCH_JOB_ID
# ctrl+c実行時にjobも一緒に落とす
trap 'eval `aws batch cancel-job --job-id $BATCH_JOB_ID --reason "KeyboardInterrupt"`; exit 1' 2 3 15
echo 'polling job status every 30 seconds before STARTING'

# RUNNABLEに留まり続ける問題対策
for i in `seq 30`
do
    sleep 30
    BATCH_JOB_STATUS=`aws batch describe-jobs --jobs $BATCH_JOB_ID | jq -r '.jobs[].status'`
    if [ $BATCH_JOB_STATUS = "SUBMITTED" ]; then
        echo "[$1]" "SUBMITTED > .."
        continue
    elif [ $BATCH_JOB_STATUS = "PENDING" ]; then
        echo "[$1]" "SUBMITTED > PENDING > .."
        continue
    elif [ $BATCH_JOB_STATUS = "RUNNABLE" ]; then
        echo "[$1]" "SUBMITTED > PENDING > RUNNABLE > .."
        continue
    elif [ "$i" = 30 ]; then
        echo "[$1]" "SUBMITTED > PENDING > RUNNABLE > .."
        echo "the job stayed at RUNNABLE over 15min. Cancelling job..." 1>&2
        aws batch cancel-job --job-id $BATCH_JOB_ID --reason "RUNNABLE over 15min"
        exit 1
    else
        break
    fi
done

echo 'polling job status every 30 seconds after RUNNING'
for i in `seq 120`
do
    sleep 30
    BATCH_JOB_STATUS=`aws batch describe-jobs --jobs $BATCH_JOB_ID | jq -r '.jobs[].status'`
    if [ $BATCH_JOB_STATUS = "STARTING" ]; then
        echo "[$1]" "SUBMITTED > PENDING > RUNNABLE > STARTING > .."
        continue
    elif [ $BATCH_JOB_STATUS = "RUNNING" ]; then
        echo "[$1]" "SUBMITTED > PENDING > RUNNABLE > STARTING > RUNNING > .."
        continue
    elif [ $BATCH_JOB_STATUS = "SUCCEEDED" ]; then
        echo "[$1]" "SUBMITTED > PENDING > RUNNABLE > STARTING > RUNNING > SUCCEEDED"
        exit 0
    elif [ $BATCH_JOB_STATUS = "FAILED" ]   ; then
        echo "[$1]" "SUBMITTED > PENDING > RUNNABLE > STARTING > RUNNING > FAILED" 1>&2
        exit 1
    fi
done
echo "[$1]" "job time over 3600 seconds. Cancelling job." 1>&2
aws batch cancel-job --job-id $BATCH_JOB_ID --reason "job time over 3600 seconds. Cancelling job."
exit 1