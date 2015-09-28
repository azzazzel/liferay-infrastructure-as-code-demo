#!/bin/bash 

LOG_FILE="/dev/null"
IMAGE=$1 
PRIVATE_REPO=$2 


if [ -z "$IMAGE" ] ; then 
	echo "Please provide image (in the form of 'repo/name:tag') to push to private repo!"
	exit 1 
fi 

if [ -z "$PRIVATE_REPO" ] ; then 
	PRIVATE_REPO="docker.private:5000"
fi 

echo $IMAGE
echo $PRIVATE_REPO

docker inspect $IMAGE >> $LOG_FILE 2>&1 
if [ $? -ne 0 ]; then
	docker pull $IMAGE 
	if [ $? -ne 0 ]; then
		echo "It seams there is no image '$IMAGE' available!"
		exit 1
	fi	
fi

if [[ $IMAGE =~ .*\/.* ]]
then
	arr=(${IMAGE//\// })
	IMAGE_NAME=${arr[1]}
else
	IMAGE_NAME=$IMAGE
fi

echo $IMAGE_NAME

docker rmi $PRIVATE_REPO/$IMAGE_NAME
docker tag $IMAGE $PRIVATE_REPO/$IMAGE_NAME
docker push $PRIVATE_REPO/$IMAGE_NAME