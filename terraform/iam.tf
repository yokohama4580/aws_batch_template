# コンソールからウィザードを実行すると以下のロールと同等のロールが作成されるため、
# 名前のバッティングを回避する目的で"2"とつけています。

resource "aws_iam_role" "AWSBatchServiceRole2" {
  name  = "AWSBatchServiceRole2"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "batch.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name = "terraform batch"
  }
}

data "aws_iam_policy" "AWSBatchServiceRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_iam_role_policy_attachment" "AWSBatchServiceRole2-attach" {
  role       = aws_iam_role.AWSBatchServiceRole2.name
  policy_arn = data.aws_iam_policy.AWSBatchServiceRole.arn
}

resource "aws_iam_instance_profile" "AWSBatchServiceRole2" {
  name = "AWSBatchServiceRole2"
  role = aws_iam_role.AWSBatchServiceRole2.name
}

resource "aws_iam_role" "ecsInstanceRole2" {
  name  = "ecsInstanceRole2"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name = "terraform batch"
  }
}

data "aws_iam_policy" "AmazonEC2ContainerServiceforEC2Role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecsInstanceRole2-attach" {
  role       = aws_iam_role.ecsInstanceRole2.name
  policy_arn = data.aws_iam_policy.AmazonEC2ContainerServiceforEC2Role.arn
}

resource "aws_iam_instance_profile" "ecs_instance_role2" {
  name = "ecs_instance_role2"
  role = aws_iam_role.ecsInstanceRole2.name
}