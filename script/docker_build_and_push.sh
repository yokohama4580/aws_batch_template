#!/bin/sh -eu

# プロジェクトルート
BASE_DIR=$(cd $(dirname $0) && pwd)

# 引数チェック
if [ $# -ne 1 ]; then
  echo "実行するには引数にbuildする対象を指定してください。" 1>&2
  echo "weekly" 1>&2
  echo "monthly" 1>&2
  exit 1
fi

echo 'TARGET=' ${1}
TARGET=${1}

# docker build ~ AWS ECRへのプッシュ
AWS_ECR_REPOSITORY_NAME=$AWS_ECR_REPOSITORY_PREFIX/$TARGET
docker build -t $AWS_ECR_REPOSITORY_NAME -f $BASE_DIR/dockerfiles/$TARGET/Dockerfile .

AWS_ACCOUNT=`aws sts get-caller-identity | jq -r '.Account'`
echo "アカウントID：$AWS_ACCOUNT"

echo '# ECRレポジトリの存在チェック=>なければ作成'
aws ecr describe-repositories | jq -r '.repositories[].repositoryName' | grep -e "^$AWS_ECR_REPOSITORY_NAME$" \
|| aws ecr create-repository --repository-name $AWS_ECR_REPOSITORY_NAME

echo "dockerイメージにタグ付け（tag: $AWS_ECR_REPOSITORY_NAME ）"
docker tag ${AWS_ECR_REPOSITORY_NAME}:latest ${AWS_ACCOUNT}.dkr.ecr.ap-northeast-1.amazonaws.com/${AWS_ECR_REPOSITORY_NAME}:latest

eval `aws ecr get-login --no-include-email`
docker push ${AWS_ACCOUNT}.dkr.ecr.ap-northeast-1.amazonaws.com/${AWS_ECR_REPOSITORY_NAME}:latest

# AWS Batchの作成
AWS_BATCH_JOB_NAME=$AWS_ECR_REPOSITORY_PREFIX-$TARGET
export TF_VAR_AWS_ECR_REPOSITORY_NAME=$AWS_ECR_REPOSITORY_NAME
export TF_VAR_AWS_BATCH_JOB_NAME=$AWS_BATCH_JOB_NAME
export TF_VAR_AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION

cd $BASE_DIR/terraform/environments/$TARGET
pwd
terraform init
terraform apply -auto-approve

echo 'AWS Batch job definition='$AWS_BATCH_JOB_NAME