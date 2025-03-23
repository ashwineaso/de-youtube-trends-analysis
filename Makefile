# Build the lambda to a zip file
# Usage: make build --LAMBDA=<lambda_name>
build-lambda:
	# Call shell script to build the lambda
	./scripts/build-lambda.sh $(LAMBDA)


deploy-lambda:
	# Call shell script to deploy the lambda
	./scripts/deploy-lambda.sh $(LAMBDA)