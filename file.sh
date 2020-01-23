#!/bin/bash
client=$1
env=$2
region=$3
action=$4
stack=$5
certificateArn=$5
BMDToolVersion=$6
BMDToolMinorVersion=$7

export ClientName=$1
export BMDToolVersion=$6

if [[ $stack == "emr-prereq" && $action == "create" ]];
then
  aws ec2 create-key-pair --key-name $client-emr-ssh --query "KeyMaterial" --region us-east-1 --output text > /tmp/$client-emr-ssh.pem
  chmod 777 /tmp/$client-emr-ssh.pem
  aws s3 cp /tmp/$client-emr-ssh.pem s3://$env-fico-ddc-efx-bucket/Customers/$client/$client-emr-ssh.pem --region us-east-1
  aws s3 cp dashboard-config.json s3://$env-fico-ddc-efx-bucket/Customers/$client/dashboard-config.json --region us-east-1
fi

if [[ $stack == "emr-prereq" && $action == "delete" ]];
then
  aws ec2 delete-key-pair --key-name $client-emr-ssh --region us-east-1
  aws s3 rm s3://$env-fico-ddc-efx-bucket/Customers/$client/ --region us-east-1 --recursive
  export kmskey=$(aws kms describe-key --key-id alias/dms-ignite-$env-$client-kms-key --region us-east-1 --output text --query KeyMetadata.Arn)
  echo $kmskey
  aws kms schedule-key-deletion --key-id $kmskey --pending-window-in-days 7 --region us-east-1
fi


if [[ $stack == "emr-main" && $action == "create" ]];
then
  cert_arn=$(aws ssm get-parameter --region us-east-1 --name "/fico/$env/$client/emr-cert-arn" --query Parameter.Value --output text)
  export CertificateARN=$cert_arn
fi

echo $client
echo $env
echo $region
echo $action
echo $cert_arn
export CertificateARN=$cert_arn

function check_var {
    if [[ -z "${2}"  ]]
    then
    echo "Make sure all the variables must have valid values; Null Value for variable": ${1}
    exit 1
    fi
}

function create_stack {
  aws cloudformation create-stack --region $region --stack-name $client-$env-$stack --capabilities CAPABILITY_NAMED_IAM --template-url ${fico_template_s3url} --parameters $(cat ${client}-${env}-${stack}_parameters | tr '\n' ' ') 
  echo "Waiting for stack to be created ..."
  aws cloudformation wait stack-create-complete --region $region --stack-name $client-$env-$stack 
  stack_status=$(aws cloudformation describe-stacks --stack-name $client-$env-$stack --region us-east-1 --output text --query "Stacks[*].StackStatus")
  if [ $stack_status == "CREATE_COMPLETE"]
    echo "stack creation successful $client-$env-$stack"
    exit 0
  else
    echo "Stack Creation Failed"
    exit 66
  fi

}

function delete_stack {
  echo -e "Stack exist, deleting $client-$env-$stack"
  aws cloudformation delete-stack --region $region --stack-name $client-$env-$stack

  echo "Waiting for stack to be deleted ..."
  aws cloudformation wait stack-delete-complete --region $region --stack-name $client-$env-$stack 
  echo "Finished deleted successfully!"
}
if [[ $action != "create" && $action != "delete" ]];
then
  echo "Invalid action $action"
  exit 33
fi

if [[ $stack != "emr-prereq" && $stack != "emr-main" && $stack != "s3" ]];
then
  echo "Invalid stack"
  exit 44
fi

if [[ $action == "delete" ]];
then
  if aws cloudformation describe-stacks --region $region --stack-name $client-$env-$stack ; then
    delete_stack  $region $client-$env-$stack
    exit 0
  else
      echo -e "stack $client-$env-$stack does not exist, exiting"
      exit 55
  fi
fi
template="$stack.yaml"
params="parameters-$env"

if [[ $action == "create" ]];
then
  if [[ ! -f "$template" || ! -f "$params" ]]; then
    echo "Required File doesnot exist"
    exit 66
  fi
    
  date=`date +%Y-%m-%d_%H:%M`
  source $params

  aws s3 cp $template s3://$env-fico-ddc-efx-bucket/emr-template/$template-$date.yaml
  fico_template_s3url=https://s3.amazonaws.com/$(echo s3://$env-fico-ddc-efx-bucket/emr-template/$template-$date.yaml | sed 's|s3\:\/\/||g')
  rm -f ${client}-${env}-${stack}_parameters
  for i in $(echo $(aws cloudformation validate-template --region ${Region} \
      --template-url ${fico_template_s3url} \
      --query Parameters[].ParameterKey --output text) | tr ' ' '\n')
      do
          check_var ${!i@} ${i}
          echo "ParameterKey=$i,ParameterValue=$(eval "echo \${$i}")" >> ${client}-${env}-${stack}_parameters
      done
      cat ${client}-${env}-${stack}_parameters
  if ! aws cloudformation describe-stacks --region $region --stack-name $client-$env-$stack ; then
    echo -e "Stack does not exist, creating $client-$env-$stack\n"
    create_stack 
  else
    stack_status=$(aws cloudformation describe-stacks --region $region --stack-name $client-$env-$stack --query "Stacks[*].StackStatus"  --output text)
    if [[ $stack_status == "ROLLBACK_COMPLETE" !! $stack_status != "ROLLBACK_FAILED" ]];
    then
      delete_stack
      create_stack
      exit 0
    else
      echo -e "Stack exists, updating the stack $client-$env-$stack"
      cf_stack_status=$(aws cloudformation describe-stacks --stack-name $client-$env-$stack --region us-east-1 --output text --query "Stacks[*].StackStatus")
      set +e
      update_output=$( aws cloudformation update-stack --region $region --stack-name $client-$env-$stack --capabilities CAPABILITY_NAMED_IAM --template-url ${fico_template_s3url} --parameters $(cat ${client}-${env}-${stack}_parameters | tr '\n' ' '))
      status=$?
      set -e
      echo "$update_output"
      if [ $status -ne 0 ] ; then
          if [[ $update_output == *"ValidationError"* && $update_output == *"No updates"* ]] ; then
            echo -e "Error creating/updating\n"
            exit 0
          else
            exit $status
          fi
      fi
      echo "Waiting for stack update to complete\n"
      aws cloudformation wait stack-update-complete --region $region --stack-name $client-$env-$stack 
    fi
  fi
  echo "Updation of stack $client-$env-$stack completed successfully!"
  exit 0
fi

######################################################################EMR-PREREQ-DELETE##########################################################
deploy.sh
Displaying deploy.sh.
