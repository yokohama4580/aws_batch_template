#!/bin/sh -eu

# プロジェクトルート
BASE_DIR=$(cd $(dirname $0) && pwd)

# 引数チェック
if [ $# -ne 1 ]; then
  echo "実行するには引数にbuild対象を指定してください。" 1>&2
  ls $BASE_DIR/jobs/
  exit 1
fi

echo 'TARGET=' ${1}
TARGET=${1}

# docker build ~ AWS ECRへのプッシュ
AWS_ECR_REPOSITORY_NAME=$AWS_ECR_REPOSITORY_PREFIX/$TARGET
docker build --build-arg TARGET_JOB=$TARGET -t $AWS_ECR_REPOSITORY_NAME -f $BASE_DIR/jobs/$TARGET/Dockerfile .

echo '# ECRレポジトリの存在チェック=>なければ作成'
aws ecr describe-repositories | jq -r '.repositories[].repositoryName' | grep -e "^$AWS_ECR_REPOSITORY_NAME$" \
|| aws ecr create-repository --repository-name $AWS_ECR_REPOSITORY_NAME

AWS_ECR_REPOSITORY_URI=`aws ecr describe-repositories | \
jq -r --arg ECR_REPO $AWS_ECR_REPOSITORY_NAME '.repositories[] | select (.repositoryName == $ECR_REPO) | .repositoryUri'`

echo "dockerイメージにタグ付け（tag: $AWS_ECR_REPOSITORY_NAME ）"
docker tag ${AWS_ECR_REPOSITORY_NAME}:latest $AWS_ECR_REPOSITORY_URI:latest

eval `aws ecr get-login --no-include-email`
docker push $AWS_ECR_REPOSITORY_URI:latest

# AWS Batchの作成
AWS_BATCH_JOB_NAME=$AWS_ECR_REPOSITORY_PREFIX-$TARGET

aws batch register-job-definition \
--job-definition-name $AWS_BATCH_JOB_NAME \
--type container --container-properties \
'{ "image": "'$AWS_ECR_REPOSITORY_URI'", "vcpus": 1, "memory": 128, "command": []}'

echo 'AWS Batch job definition='$AWS_BATCH_JOB_NAME