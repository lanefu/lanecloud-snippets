#!/bin/bash
CONSUL_HTTP_ADDRESS=examplehost:8500
SERVICES="lctest1"
echo "## runner info ##"
echo
for SERVICE in ${SERVICES}; do
	echo ${SERVICE}
	curl -s http://${CONSUL_HTTP_ADDRESS}/v1/catalog/service/${SERVICE}|jq '.[]|[.Address, .ServicePort]| @csv' -r|tr -d '"' | tr ',' ':'
	echo
done
