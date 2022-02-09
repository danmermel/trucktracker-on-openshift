#!/bin/zsh
#this script has to run after all other terraform actions have happened. 
#So the TF command to run it has to depend_on all the other actions

## remove these two lines before commiting!!
alias docker=podman
ibmcloud iam oauth-tokens | sed -ne '/IAM token/s/.* //p' | podman login -u iambearer --password-stdin uk.icr.io


#first copy the terraform output to a creds file
cd terraform
terraform output -json > ../creds.json
cd ..

#make sure your account is targeting a resource group
RG=`cat creds.json | jq '.resource_group_name.value' | sed 's/"//g'`
ibmcloud target -g "$RG" 

#let docker access your ibm container registry
ibmcloud cr login

#go into each folder, build the docker images and push to container registry
cd cloudantConsumer
docker build -t cloudantconsumer .
docker tag cloudantconsumer uk.icr.io/trucktracker/cloudantconsumer:latest
docker push uk.icr.io/trucktracker/cloudantconsumer:latest 

cd ../redisConsumer
docker build -t redisconsumer .
docker tag redisconsumer uk.icr.io/trucktracker/redisconsumer:latest
docker push uk.icr.io/trucktracker/redisconsumer:latest 

cd ../producer
docker build -t producer .
docker tag producer uk.icr.io/trucktracker/producer:latest
docker push uk.icr.io/trucktracker/producer:latest 

cd ../web
docker build -t web .
docker tag web uk.icr.io/trucktracker/web:latest
docker push uk.icr.io/trucktracker/web:latest 
cd ..

#create variables for the redis credentials secret
CA=`cat creds.json | jq '.redis_credentials.value."connection.rediss.certificate.certificate_base64"'| sed 's/"//g' `
URL=`cat creds.json | jq '.redis_credentials.value."connection.rediss.composed.0"' | sed 's/"//g'`

#create a rediscreds kubernetes secret
kubectl create secret generic rediscreds \
  --"from-literal=ca=$CA" \
  --"from-literal=url=$URL"

BROKER0=`cat creds.json | jq '.eventstreams_credentials.value."kafka_brokers_sasl.0"' | sed 's/"//g' `
BROKER1=`cat creds.json | jq '.eventstreams_credentials.value."kafka_brokers_sasl.1"' | sed 's/"//g' `
BROKER2=`cat creds.json | jq '.eventstreams_credentials.value."kafka_brokers_sasl.2"' | sed 's/"//g' `
BROKER3=`cat creds.json | jq '.eventstreams_credentials.value."kafka_brokers_sasl.3"' | sed 's/"//g' `
BROKER4=`cat creds.json | jq '.eventstreams_credentials.value."kafka_brokers_sasl.4"' | sed 's/"//g' `
BROKER5=`cat creds.json | jq '.eventstreams_credentials.value."kafka_brokers_sasl.5"' | sed 's/"//g' `
USER_NAME=`cat creds.json | jq '.eventstreams_credentials.value.user' | sed 's/"//g'`
PASSWORD=`cat creds.json | jq '.eventstreams_credentials.value.password' | sed 's/"//g'`


#create a kafka kubernetes secret
kubectl create secret generic kafkacreds \
  --"from-literal=broker0=$BROKER0" \
  --"from-literal=broker1=$BROKER1" \
  --"from-literal=broker2=$BROKER2" \
  --"from-literal=broker3=$BROKER3" \
  --"from-literal=broker4=$BROKER4" \
  --"from-literal=broker5=$BROKER5" \
  --"from-literal=user_name=$USER_NAME" \
  --"from-literal=password=$PASSWORD"

API_KEY=`cat creds.json | jq '.cloudant_credentials.value.apikey' | sed 's/"//g'`
CLOUDANT_URL=`cat creds.json | jq '.cloudant_credentials.value.url' | sed 's/"//g'`

#create a cloudant kubernetes secret
kubectl create secret generic cloudantcreds \
  --"from-literal=api_key=$API_KEY" \
  --"from-literal=cloudant_url=$CLOUDANT_URL"

#deploy all pods to Openshift
oc apply -f deployment.yaml

#Expose the web app to the internet
oc expose svc/trucktrackerweb

URL=`oc get route -o json | jq ".items[0].spec.host" | sed 's/"//g' | sed 's/^/http:\/\//'`
echo "Visit this URL in your browser: $URL" 

