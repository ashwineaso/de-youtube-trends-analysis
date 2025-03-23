#!/bin/bash

# Check if the required environment variables are set
if [ -z "$LAMBDA" ]; then
  echo "Error: LAMBDA environment variable is not set."
  exit 1
fi

# If the AWS_PROFILE environment variable is not set
# then use the default profile
if [ -z "$AWS_PROFILE" ]; then
  AWS_PROFILE="default"
fi

# Deploy the lambda function
echo "Deploying lambda: $LAMBDA using profile: $AWS_PROFILE"
aws lambda update-function-code --function-name "lambda-$LAMBDA" --zip-file "fileb://lambda/$LAMBDA/$LAMBDA.zip" --profile $AWS_PROFILE


if [ $? -eq 0 ]; then
  echo "Lambda function $LAMBDA deployed successfully."
else
  echo "Failed to deploy lambda function $LAMBDA."
  exit 1
fi