import csv
import os
import tempfile
import time
import datetime
from typing import List

import googleapiclient.discovery
import googleapiclient.errors
import boto3

from feature import prepare_feature, prepare_tags

DEVELOPER_KEY = os.getenv('YOUTUBE_DATA_API_KEY')
RAW_DATA_BUCKET = os.getenv('RAW_DATA_BUCKET')
COUNTRY_CODES = os.getenv('COUNTRY_CODES')

scopes = ["https://www.googleapis.com/auth/youtube.readonly"]

video_snippet_attributes = [
    "title",
    "publishedAt",
    "channelId",
    "channelTitle",
    "categoryId"
]

header = ["video_id"] + video_snippet_attributes + [
    "description",
    "tags",
    "trendingDate",
    "viewCount",
    "likes",
    "dislikes",
    "commentCount",
    "favourites",
    "ratingsDisabled",
]


def parse_items(items: List[dict]) -> List[dict]:
    videos = []

    for video in items:

        video_details = {}

        # If the video does not have the statistics key
        # then skip the video
        if 'statistics' not in video:
            continue

        video_details['video_id'] = video['id']
        snippet = video['snippet']
        statistics = video['statistics']

        # Extract the snippet attributes
        for attribute in video_snippet_attributes:
            video_details[attribute] = prepare_feature(snippet.get(attribute, ''))

        # Extract the description of the video
        video_details['description'] = prepare_feature(snippet.get('description', ''))

        # Extract the tags of the video and combine them into a single string delimited by a pipe
        video_details['tags'] = prepare_tags(snippet.get('tags', []))

        # Extract the trending date
        video_details['trendingDate'] = time.strftime("%Y-%m-%d")

        # Count the number of likes, dislikes, views and comments
        video_details['viewCount'] = statistics.get('viewCount', 0)
        video_details['likes'] = statistics.get('likeCount', 0)
        video_details['dislikes'] = statistics.get('dislikeCount', 0)
        video_details['commentCount'] = statistics.get('commentCount', 0)
        video_details['favourites'] = statistics.get('favouritesCount', 0)

        # Check if the video has ratings disabled
        ratings_disabled = False
        if 'likeCount' in statistics and 'likeCount' in statistics:
            ratings_disabled = True
        video_details['ratingsDisabled'] = ratings_disabled

        videos.append(video_details)

    return videos


def scrape_data(country_code: str) -> List[dict]:
    print(f'Scraping data for country code: {country_code}')

    country_data: List[dict] = []

    # Disable OAuthlib's HTTPS verification when running locally.
    # *DO NOT* leave this option enabled in production.
    os.environ["OAUTHLIB_INSECURE_TRANSPORT"] = "1"

    api_service_name = "youtube"
    api_version = "v3"

    # Get credentials and create an API client
    youtube = googleapiclient.discovery.build(
        api_service_name, api_version, developerKey=DEVELOPER_KEY)

    page_token = ''
    while True:
        request = youtube.videos().list(
            part="snippet,contentDetails,statistics",
            chart="mostPopular",
            pageToken=page_token,
            regionCode=country_code,
        )
        response = request.execute()

        # If the response has items
        # then parse the response and append the items to the country data
        if 'items' in response:
            country_data.extend(parse_items(response.get('items', [])))

        # If the response has a nextPageToken
        # then set the page_token to the nextPageToken
        page_token = response.get('nextPageToken')
        if not page_token:
            break

    return country_data


def save_data(country_data: List[dict]) -> str:
    temp_file = tempfile.NamedTemporaryFile(delete=False)
    with open(temp_file.name, mode='w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=header, extrasaction='ignore')
        writer.writeheader()
        for video in country_data:
            writer.writerow(video)

    return temp_file.name


def upload_file_to_s3(file_path: str, country_code: str, current_time: datetime.datetime):
    print(f'Uploading file to S3: {file_path}')

    client = boto3.client('s3')
    object_name = f'raw_data/country={country_code}/date={time.strftime("%Y-%m-%d")}/{current_time.strftime("%H.%M")}.csv'
    client.upload_file(file_path, RAW_DATA_BUCKET, object_name)


def cleanup(file_path: str):
    print(f'Cleaning up file: {file_path}')
    os.remove(file_path)


def handler(event, context):
    """Entry point for the lambda"""
    print(f'Received event: {event}')
    print(f'Received context: {context}')

    current_time = datetime.datetime.utcnow()

    countries = COUNTRY_CODES.split(',')
    for country_code in countries:
        country_data = scrape_data(country_code)
        file_path = save_data(country_data)
        upload_file_to_s3(file_path, country_code, current_time)
