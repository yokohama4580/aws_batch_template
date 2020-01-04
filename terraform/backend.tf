terraform {
  backend "s3" {
    bucket = "tf-backend-yokohama4580"
    key    = "aws_batch.tfstate"
    region = "ap-northeast-1"
  }
}