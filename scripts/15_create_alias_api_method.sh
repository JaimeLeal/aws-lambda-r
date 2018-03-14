#!/bin/bash


# API method for API_ALIAS_RESOURCE_NAME
echo
echo -e "$INFO API method for Resource $(FC $API_ALIAS_RESOURCE_NAME)"

API_ALIAS_METHOD=$(aws apigateway get-method \
    --rest-api-id $API_GATEWAY_ID \
    --resource-id $API_ALIAS_RESOURCE_ID \
    --http-method $API_HTTP_METHOD \
    --query httpMethod \
    --output text)

# Delete API method if already exists
if [[ "$API_ALIAS_METHOD" == "$API_HTTP_METHOD" ]]; then
   echo -e "$INFO  Deleting previous HTTP method"
   aws apigateway delete-method \
        --rest-api-id $API_GATEWAY_ID \
        --resource-id $API_ALIAS_RESOURCE_ID \
        --http-method $API_HTTP_METHOD \
        --output table 
fi

# Creating API method under specified resource
echo -e "$INFO Creating ${API_HTTP_METHOD} under ${API_ALIAS_RESOURCE_NAME} resource"
aws apigateway put-method \
    --rest-api-id $API_GATEWAY_ID \
    --resource-id $API_ALIAS_RESOURCE_ID \
    --http-method $API_HTTP_METHOD \
    --authorization-type $API_AUTHORIZATION_TYPE \
    --authorizer-id $API_AUTHORIZER_ID \
    --output table

echo -e "$INFO API put-integration."
aws apigateway put-integration \
    --rest-api-id $API_GATEWAY_ID \
    --resource-id $API_ALIAS_RESOURCE_ID \
    --http-method $API_HTTP_METHOD \
    --type AWS \
    --integration-http-method $API_HTTP_METHOD \
    --uri "arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
    --output table

echo -e "$INFO API put-method-response."   
aws apigateway put-method-response \
    --rest-api-id $API_GATEWAY_ID \
    --resource-id $API_ALIAS_RESOURCE_ID \
    --http-method $API_HTTP_METHOD \
    --status-code 200 \
    --response-models '{"application/json": "Empty"}' \
    --output table

echo -e "$INFO API put-integration-response."
aws apigateway put-integration-response \
    --rest-api-id $API_GATEWAY_ID \
    --resource-id $API_ALIAS_RESOURCE_ID \
    --http-method $API_HTTP_METHOD \
    --status-code 200 \
    --selection-pattern "-" \
    --output table


# Adding permission for internal calls
echo -e "$INFO API add-permission for internal calls." 
aws lambda add-permission \
    --function-name $LAMBDA_ARN \
    --source-arn "${API_ARN}/*/${API_HTTP_METHOD}/${API_ALIAS_RESOURCE_NAME}" \
    --principal apigateway.amazonaws.com \
    --statement-id api-lambda-permission-3 \
    --action lambda:InvokeFunction 


# Adding permission for external calls
echo -e "$INFO API add-permission for external calls." 
aws lambda add-permission \
    --function-name $LAMBDA_ARN \
    --source-arn "${API_ARN}/${API_STAGE}/${API_HTTP_METHOD}/${API_ALIAS_RESOURCE_NAME}" \
    --principal apigateway.amazonaws.com \
    --statement-id api-lambda-permission-4 \
    --action lambda:InvokeFunction 

echo -e "$INFO Finished creating $(FC $API_HTTP_METHOD) under resource" \
    "$(FC $API_ALIAS_RESOURCE_NAME)" 
 

echo -e "$INFO API create-deployment." 
aws apigateway create-deployment \
    --rest-api-id $API_GATEWAY_ID \
    --stage-name $API_STAGE \
    --description $LAMBDA_FUNCTION_NAME \
    --output table

echo -e "$INFO API stage updating description."    
aws apigateway update-stage \
    --rest-api-id $API_GATEWAY_ID \
    --stage-name $API_STAGE \
    --patch-operations "op=replace,path=/description,value=${LAMBDA_FUNCTION_NAME}" \
    --output table

# testing API alias resource
echo
echo -e "$INFO Testing $(FC ${API_STAGE}/${API_ALIAS_RESOURCE_NAME}) call."
CURL_OUT=$(curl -H "Auth: ${API_TOKEN}" \
    -H  "Content-Type: application/json" \
    -X ${API_HTTP_METHOD} \
    -d '{"request_id": 1111}' \
    https://${API_GATEWAY_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}/${API_ALIAS_RESOURCE_NAME})
[[ ${#CURL_OUT} -gt 1000 ]] || echo "$CURL_OUT"
