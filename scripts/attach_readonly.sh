#!/bin/bash
for A in 223634394676 339712901782 590183713498 471112907214 050752654368 866445667300 910617026399 047719642223 851725206747 024268545623 797760781722 202210529120 876982715609 960341592326 587128718552; do
  echo "→ $A"
  C=$(aws sts assume-role --role-arn "arn:aws:iam::${A}:role/OdinInventoryReadOnly" --role-session-name "up" --output json 2>&1)
  if echo "$C" | jq -e .Credentials > /dev/null 2>&1; then
    export AWS_ACCESS_KEY_ID=$(echo "$C" | jq -r .Credentials.AccessKeyId)
    export AWS_SECRET_ACCESS_KEY=$(echo "$C" | jq -r .Credentials.SecretAccessKey)
    export AWS_SESSION_TOKEN=$(echo "$C" | jq -r .Credentials.SessionToken)
    aws iam attach-role-policy --role-name OdinInventoryReadOnly --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess 2>&1 && echo "  OK" || echo "  DENIED"
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
  else
    echo "  FALLO"
  fi
done
