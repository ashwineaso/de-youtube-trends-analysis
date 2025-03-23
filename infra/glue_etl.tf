resource "aws_glue_job" "de_proj_youtube_trends_etl" {
  name     = "de-proj-youtube-trends-etl"
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${var.proj_bucket}/scripts/etl.py"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = "true"
    "--TempDir"                          = "s3://${var.proj_bucket}/glue-temp"
  }

  glue_version      = "3.0"
  number_of_workers = 2
  worker_type       = "G.1X"

  depends_on = [aws_iam_role_policy_attachment.glue_s3_policy]
}