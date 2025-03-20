resource "aws_scheduler_schedule" "youtube_trends_scraper" {
  name       = "youtube-trends-scraper"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(4 hours)"

  target {
    arn      = aws_lambda_function.lambda.arn
    role_arn = aws_iam_role.scheduler.arn
  }
}

resource "aws_iam_role" "scheduler" {
  name = "scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = ["scheduler.amazonaws.com"]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "scheduler" {
  name        = "scheduler-policy"
  description = "Allow scheduler to invoke lambda"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "lambda:InvokeFunction",
        Resource = aws_lambda_function.lambda.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler" {
  policy_arn = aws_iam_policy.scheduler.arn
  role       = aws_iam_role.scheduler.name
}