# aws_batch_template
 
[AWS Batch](https://aws.amazon.com/jp/batch/)の構築と実行のためのterraformとスクリプト
 
# Features
 
- terraformでAWS上に簡単にAWS Batch環境が構築できる
- docker buildからECRへのdocker push、(初回のみ)バッチジョブ定義の作成が1スクリプトで実行できる
- AWS Batchの実行状況がコンソールで確認できる
 
# Requirement
以下環境での実行確認済み。 
- MacOS Mojave
- docker
- aws-cli
 
# Installation
後で記載予定
 
# Usage
```bash
git clone https://github.com/yokohama4580/aws_batch_template
cd aws_batch_template
```

## 環境変数の設定
- 以下環境変数をset。（[direnv]()での管理推奨。）

```.envrc
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_DEFAULT_REGION=

export AWS_ECR_REPOSITORY_PREFIX=
```

## AWSリソースの作成
- terraform/backend.tfに保存先のS3バケットを記載。

```backend.tf
terraform {
  backend "s3" {
    bucket = "hogepiyo"
    key    = "aws_batch.tfstate"
    region = "ap-northeast-1"
  }
}
```
- プロジェクトルートで`terraform init`
- プロジェクトルートで`terraform apply --auto-approve`

## docker build~docker push~ジョブ定義の作成
- プロジェクトルートで`script/docker_build_and_push.sh`を実行

## ジョブの実行
- プロジェクトルートで`script/submit_job_and_polling_status.sh`を実行 => 実行状況がコンソールに表示されます
 
# Note
 
以下のawsリソースのtfファイルを用意しているので、利用状況に応じて不要なものを削除して利用ください。
- VPC/subnet
- security group
- NAT gateway/Internet gateway
- IAM role/Instance profile
- AWS Batch Compute Engironment
- AWS Batch Job Queue

なお、ECRはスクリプトの中で必要に応じて作成しているので、terraform管理ではありません。
 
# Author
  
* yokohama4580
* naoya4580tech@gmail.com
 
# License
 
"aws_batch_template" is under [MIT license](https://en.wikipedia.org/wiki/MIT_License).
