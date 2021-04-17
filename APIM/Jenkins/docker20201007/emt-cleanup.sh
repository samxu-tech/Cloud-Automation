#!/bin/sh

cleanup() {
    echo "*** Cleaning up docker ***"
    docker rm -f anm analytics apimgr apigw cassandra2212 metricsdb || true
    docker rmi admin-node-manager apigw-analytics apimanager1-mgr apigateway1-demo apigw-base || true
    docker network rm api-gateway-domain || true
    echo "*** Cleaning up completed ***"
}

cleanup

