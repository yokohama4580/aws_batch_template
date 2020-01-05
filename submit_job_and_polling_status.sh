#!/bin/sh -eu
# 引数チェック
if [ $# -ne 1  ]; then
  echo "実行するには引数にaws batchのjob definitionを指定してください。" 1>&2
  exit 1
fi

echo 'TARGET=' ${1}
TARGET=${1}
AWS_BATCH_JOB_QUEUE=optimal_job_queue

BATCH_JOB_ID=`aws batch submit-job --job-name $TARGET --job-queue $AWS_BATCH_JOB_QUEUE \
--job-definition $TARGET | jq -r '.jobId'`
if [ -z "$BATCH_JOB_ID" ]; then
  echo "SubmitJob failed" 1>&2
  exit 1
fi
echo "batch job-id is $BATCH_JOB_ID"
# ctrl+c実行時にjobも一緒に落とす
trap 'eval `aws batch cancel-job --job-id $BATCH_JOB_ID --reason "KeyboardInterrupt"`; exit 1' 2 3 15

# RUNNABLEに留まり続ける問題対策
SLEEP_TIME=30
MAX_TRY=30
echo "SLEEP_TIME=$SLEEP_TIME"
echo "MAX_TRY=$MAX_TRY"
echo "polling job status every $SLEEP_TIME seconds before STARTING"
for i in `seq $MAX_TRY`
do
    sleep $SLEEP_TIME
    BATCH_JOB_STATUS=`aws batch describe-jobs --jobs $BATCH_JOB_ID | jq -r '.jobs[].status'`
    if [ $BATCH_JOB_STATUS = "SUBMITTED" ]; then
        echo $i/$MAX_TRY "[$TARGET]" "SUBMITTED > .."
        continue
    elif [ $BATCH_JOB_STATUS = "PENDING" ]; then
        echo $i/$MAX_TRY "[$TARGET]" "SUBMITTED > PENDING > .."
        continue
    elif [ $BATCH_JOB_STATUS = "RUNNABLE" ]; then
        echo $i/$MAX_TRY "[$TARGET]" "SUBMITTED > PENDING > RUNNABLE > .."
        if [ $i = $MAX_TRY ]; then
            MAX_TIME=`expr $SLEEP_TIME \* $MAX_TRY`
            echo "the job stayed at RUNNABLE over $MAX_TIME seconds. Cancelling job..." 1>&2
            aws batch cancel-job --job-id $BATCH_JOB_ID --reason "RUNNABLE over $MAX_TIME seconds"
            exit 1
        fi
        continue
    else
        break
    fi
done

SLEEP_TIME=30
MAX_TRY=120
echo "SLEEP_TIME=$SLEEP_TIME"
echo "MAX_TRY=$MAX_TRY"
echo 'polling job status every $SLEEP_TIME seconds after RUNNING'
for i in `seq $MAX_TRY`
do
    sleep $SLEEP_TIME
    BATCH_JOB_STATUS=`aws batch describe-jobs --jobs $BATCH_JOB_ID | jq -r '.jobs[].status'`
    if [ $BATCH_JOB_STATUS = "STARTING" ]; then
        echo $i/$MAX_TRY "[$TARGET]" "SUBMITTED > PENDING > RUNNABLE > STARTING > .."
        continue
    elif [ $BATCH_JOB_STATUS = "RUNNING" ]; then
        echo $i/$MAX_TRY "[$TARGET]" "SUBMITTED > PENDING > RUNNABLE > STARTING > RUNNING > .."
        if [ $i = $MAX_TRY ]; then
            MAX_TIME=`expr $SLEEP_TIME \* $MAX_TRY`
            echo "[$TARGET]" "job time over $MAX_TIME seconds. Cancelling job." 1>&2
            aws batch cancel-job --job-id $BATCH_JOB_ID --reason "job time over $MAX_TIME seconds. Cancelling job."
            exit 1
        fi
        continue
    elif [ $BATCH_JOB_STATUS = "SUCCEEDED" ]; then
        echo $i/$MAX_TRY "[$TARGET]" "SUBMITTED > PENDING > RUNNABLE > STARTING > RUNNING > SUCCEEDED"
        exit 0
    elif [ $BATCH_JOB_STATUS = "FAILED" ]   ; then
        echo $i/$MAX_TRY "[$TARGET]" "SUBMITTED > PENDING > RUNNABLE > STARTING > RUNNING > FAILED" 1>&2
        exit 1
    fi
done
