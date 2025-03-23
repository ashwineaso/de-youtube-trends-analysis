resource "aws_iam_role" "glue_role" {
  name = "glue-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "glue.amazonaws.com" },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "glue_s3_access" {
  name        = "glue_s3_access_policy"
  description = "Allows Glue to read/write from S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:ListBucket", "s3:PutObject"],
        Resource = [
          "arn:aws:s3:::${var.proj_bucket}/*",
          "arn:aws:s3:::${var.proj_bucket}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_s3_policy" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_s3_access.arn
}

resource "aws_glue_catalog_database" "youtube_trends_db" {
  name = "de-proj-youtube-trends-db"
}

resource "aws_glue_crawler" "de_proj_youtube_trends_crawler" {
  name = "de-proj-youtube-trends-crawler"
  role = aws_iam_role.glue_role.arn

  database_name = aws_glue_catalog_database.youtube_trends_db.name

  s3_target {
    path = "s3://${var.proj_bucket}/raw_data"
  }

  table_prefix = "de_proj_youtube_trends_"

  configuration = jsonencode(
    {
      CrawlerOutput = {
        Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      }
      Version = 1
    }
  )

  depends_on = [aws_glue_catalog_database.youtube_trends_db]
}