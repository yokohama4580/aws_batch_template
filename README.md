# aws_batch_template
 
[AWS Batch](https://aws.amazon.com/jp/batch/)の構築と実行のためのterraformとスクリプト
 
# Features
 
- terraformでAWS上に簡単にAWS Batch環境が構築できる
- docker buildからECRへのdocker push、(初回のみ)バッチジョブ定義の作成が1スクリプトで実行できる
- AWS Batchの実行状況がコンソールで確認できる
- RUNNABLE状態で止まり続ける問題や、実行時間が長すぎる問題に対処できるよう、それぞれ900秒、3600秒経過するとコンテナを落とす
 
# Requirement
awscli 1.16
terraform 0.12


# Installation
```bash
brew install docker awscli direnv terraform jq
brew cask install docker
```
 
# Usage
```bash
git clone https://github.com/yokohama4580/aws_batch_template
cd aws_batch_template
```

## 環境変数の設定
- 以下環境変数をset。（[direnv](https://github.com/direnv/direnv)での管理推奨）

```.envrc
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_DEFAULT_REGION=

export AWS_ECR_REPOSITORY_PREFIX=
```

## AWSリソースの作成
- tfstate保存用のS3バケットを作成
```bash
aws s3 mb s3://hogepiyo
```
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

## docker build => docker push => ジョブ定義の作成
1. jobs/sample-jobをコピーして、適当な名前にrename e.g. weekly-job
2. jobs/{renamed-job-name}/app/配下に実行したい処理を記載
3. jobs/{renamed-job-name}/app/entrypoint.shから2.の処理を呼び出すように記載
4. jobs/{renamed-job-name}/app/Dockerfileを処理内容に応じて修正。
5. プロジェクトルートで`docker_build_and_push.sh {renamed-job-name}`を実行（処理完了後、job-definition-nemeが表示されます）

## ジョブの実行
- プロジェクトルートで`submit_job_and_polling_status.sh {job-definition-neme}`を実行 => 実行状況がコンソールに表示されます
 
# Note
 
以下のawsリソースのtfファイルを用意しているので、利用状況に応じて不要なものを削除して利用ください。
- VPC/subnet
- elastic IP
- NAT gateway/Internet gateway
- route table
- IAM role/Instance profile/Policy attach
- AWS Batch Compute Engironment
- AWS Batch Job Queue

なお、ECRとAWS Batch Job Definitionはスクリプトの中で必要に応じて作成する形式を取っているため、terraform管理ではありません。
 
# Author
  
* yokohama4580
* naoya4580tech@gmail.com
 
# License
 
"aws_batch_template" is under [MIT license](https://en.wikipedia.org/wiki/MIT_License).
