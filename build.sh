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

#copy creds to all the folders
cp creds.json cloudantConsumer/ 
cp creds.json redisConsumer/ 
cp creds.json producer/ 
cp creds.json web/

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

#deploy all pods to Openshift
oc apply -f deployment.yaml

#Expose the web app to the internet
oc expose svc/trucktrackerweb

URL=`oc get route -o json | jq ".items[0].spec.host" | sed 's/"//g' | sed 's/^/http:\/\//'`
echo "Visit this URL in your browser: $URL" 