#!/bin/sh -eu
CURRENT=$(cd $(dirname $0) && pwd)

# サンプル1. pythonでhello worldをprint
python $CURRENT/hello-world.py

# サンプル2. 権限
# AWS Batch上で実行時はインスタンスロールにS3権限を付与すれば実行可能だが、
# ローカルDocker実行時は権限不足でエラーになる
python $CURRENT/boto3-sample.py