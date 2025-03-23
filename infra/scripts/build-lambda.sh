	echo "Building lambda"
	pip3 install -r "lambda/${LAMBDA}/requirements.txt" --target "lambda/${LAMBDA}/package"
	cd "lambda/${LAMBDA}/package" || exit
	zip -r "../${LAMBDA}.zip" .
	cd ../ || exit

	# Add the lambda function code to the zip file
	zip "${LAMBDA}.zip" ./*
	rm -rf "./package"
	echo "Lambda built"