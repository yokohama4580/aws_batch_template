resource "aws_batch_compute_environment" "optimal" {

  compute_environment_name = "optimal"
  compute_resources {
    instance_role = aws_iam_instance_profile.ecs_instance_role2.arn

    instance_type = [
      "optimal",
    ]

    max_vcpus = 256
    min_vcpus = 0

    security_group_ids = [
      aws_vpc.main.default_security_group_id,
    ]

    subnets = [
      aws_subnet.private.id,
    ]

    type = "EC2"
  }
  service_role = aws_iam_role.AWSBatchServiceRole2.arn
  type         = "MANAGED"
}

resource "aws_batch_job_queue" "optimal" {

  name                 = "optimal_job_queue"
  state                = "ENABLED"
  priority             = 1
  compute_environments = [aws_batch_compute_environment.optimal.arn]

  lifecycle {
    ignore_changes = [compute_environments]
  }
}