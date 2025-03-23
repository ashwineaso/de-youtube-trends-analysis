## Data Engineering - Analysis of YouTube Trends

## 📌 Project Overview

This project is a **serverless data engineering pipeline** built on **AWS** to collect, process, and analyze YouTube
trending videos over time.
The pipeline automates the extraction of trending video data from the **YouTube API**, transforms it into a queryable
format, and enables analysis using **Amazon Athena**.

## 🚀 Architecture

### Components & Workflow

1. **AWS Lambda** (Python):
    - Scrapes trending videos from the YouTube API every **4 hours**.
    - Saves raw data as **CSV files** in an S3 bucket, partitioned by **country** and **date**.

2. **AWS Glue Crawler**:
    - Scans the raw data stored in S3.
    - Creates a **Glue Data Catalog Table** for further processing.

3. **AWS Glue ETL Job** (PySpark):
    - Cleans and transforms the raw data.
    - Converts **CSV → Parquet** for optimized storage and querying.
    - Saves processed data in an S3 bucket, partitioned for Athena.

4. **Amazon Athena**:
    - Queries transformed YouTube data using **SQL**.
    - Provides insights on trending video patterns, engagement, and growth.

5. **Amazon QuickSight** (Optional):
    - Creates **visual dashboards** for deeper insights and reporting.

## 📁 Folder Structure

```
📦 youtube-trending-pipeline
├── infra/              # Infrastructure as Code (AWS resources)
├── lambda/             # Python Lambda function for data extraction
├── scripts/            # PySpark script for Glue ETL job
├── README.md           # Project documentation
```

## 🔧 Setup & Deployment

### Prerequisites

- **AWS Account** with permissions for Lambda, Glue, S3, Athena, and IAM.
- **Terraform** installed for provisioning infrastructure.
- **Python 3.x** for local testing.
- **YouTube API Key** (Generate from Google Developer Console).

### Deploying the Infrastructure

1. **Clone the Repository**:
   ```sh
   git clone https://github.com/ashwineaso/de-youtube-trends-analysis
   cd de-youtube-trends-analysis
   ```

2. **Configure AWS Credentials**:
   ```sh
   aws configure
   ```

3. **Deploy AWS Resources using Terraform**:
   ```sh
   cd terraform
   terraform init
   terraform apply --auto-approve
   ```

4. **Upload Glue ETL Script to S3**:
   ```sh
   aws s3 cp ./scripts/youtube_trending_etl.py s3://your-scripts-bucket/scripts/
   ```

5. **Start Glue Crawler to Create Schema**:
   ```sh
   aws glue start-crawler --name youtube_trending_crawler
   ```

6. **Run the Glue ETL Job**:
   ```sh
   aws glue start-job-run --job-name youtube_trending_etl
   ```

## 🔍 Querying Data in Athena

Once the ETL job has processed data, you can query it using **Athena**.

```sql
SELECT country, title, viewCount, trendingDate
FROM youtube_trending_data
WHERE country = 'US' AND trendingDate >= '2025-03-01'
ORDER BY viewCount DESC;
```

## Visualizing Data (Optional)

- **Amazon QuickSight** can be used to create dashboards based on Athena queries.

## 💡 Future Enhancements

✅ Automate Glue ETL job using **EventBridge** triggers.  
✅ Implement **Kinesis Firehose** for real-time streaming.  
✅ Add **Sentiment Analysis** using AWS Comprehend.

## 🤝 Contributing

Feel free to fork this repo and submit pull requests with improvements or bug fixes.

## 📜 License

This project is licensed under the **GNU GENERAL PUBLIC LICENSE**. See `LICENSE` for details.

---

### Built with AWS Serverless Technologies

- AWS Lambda
- AWS Glue
- Amazon S3
- Amazon Athena
- Amazon QuickSight

