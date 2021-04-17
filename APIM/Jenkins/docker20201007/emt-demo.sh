#!/bin/sh

# Halt on error
set -e
APIGW_INSTALLER=/home/axway/Desktop/APIGateway_7.7.20200730_Install_linux-x86-64_BN02.run
LICENSE=/home/axway/Desktop/license.lic
LICENSE_ANA=/home/axway/Desktop/analytics.lic
MYSQL_JDBC_JAR=/home/axway/Desktop/mysql-connector-java-5.1.47.jar
EMT_HOME=/home/axway/Desktop/apigw-emt-scripts-2.1.0-SNAPSHOT
EMT_DIR=/home/axway/Desktop/emt-tmp
FROM_CONTAINER=/home/axway/Desktop/from-containers
EVENTS_DIR=$FROM_CONTAINER/events
GW_MERGE_DIR=$EMT_DIR/apimgr/apigateway
MGR_MERGE_DIR=$EMT_DIR/apimgr/apigateway
AGA_MERGE_DIR=$EMT_DIR/analytics
ANM_TRACE_DIR=$FROM_CONTAINER/anm/trace
GW_TRACE_DIR=$FROM_CONTAINER/apigw/trace
MGR_TRACE_DIR=$FROM_CONTAINER/apimgr/trace
AGA_TRACE_DIR=$FROM_CONTAINER/analytics/trace
REPORTS_DIR=$FROM_CONTAINER/analytics/reports
SQL_DIR=$EMT_DIR/sql
PASS_DIR=/home/axway/Desktop/password
RT_MERGE_DIR=/home/axway/Desktop/runtime-merge
RT_MERGE_GW1=$RT_MERGE_DIR/apigateway1/apigateway
RT_MERGE_MGR1=$RT_MERGE_DIR/apimanager1/apigatway

METRICS_ENV_VARS="-e METRICS_DB_URL=jdbc:mysql://metricsdb:3306/metrics?useSSL=false -e METRICS_DB_USERNAME=root -e METRICS_DB_PASS=root01"

cleanup() {
    echo "*** Cleaning up after previous run ***"
    rm -rf "$EMT_DIR"
    rm -rf "$FROM_CONTAINER"	
    docker rm -f anm analytics apimgr apigw cassandra2212 metricsdb || true
    docker rmi admin-node-manager apigw-analytics apimanager1-mgr apigateway1-demo apigw-base || true
    docker network rm api-gateway-domain || true
}

setup() {
    echo
    echo "Building and starting an API Gateway domain that contains an Admin Node Manager,"
    echo "API Manager and API Gateway Analytics."

    mkdir -p "$EVENTS_DIR" "$GW_MERGE_DIR/ext/lib" "$MGR_MERGE_DIR/ext/lib" "$AGA_MERGE_DIR/ext/lib" "$SQL_DIR"
    mkdir -p "$ANM_TRACE_DIR" "$GW_TRACE_DIR" "$MGR_TRACE_DIR" "$AGA_TRACE_DIR" "$REPORTS_DIR"
    cp "$MYSQL_JDBC_JAR" "$GW_MERGE_DIR/ext/lib"
    cp "$MYSQL_JDBC_JAR" "$MGR_MERGE_DIR/ext/lib"
    cp "$MYSQL_JDBC_JAR" "$AGA_MERGE_DIR/ext/lib"   
    cp $EMT_HOME/quickstart/mysql-analytics.sql $SQL_DIR

    echo
    echo "*** Creating Docker network to allow containers to communicate with one another ***"
    docker network create api-gateway-domain
    echo
    echo "*** Starting Cassandra container to store API Manager data ***"
    docker run -d --name=cassandra2212 --network=api-gateway-domain cassandra:2.2.12
    echo
    echo "*** Starting MySQL container to store metrics data ***"
    docker run -d --name metricsdb --network=api-gateway-domain \
               -v $SQL_DIR:/docker-entrypoint-initdb.d \
               -e MYSQL_ROOT_PASSWORD=root01 -e MYSQL_DATABASE=metrics \
               mysql:5.7
    echo
    echo "*** Generating default domain certificate ***"
    $EMT_HOME/gen_domain_cert.py --domain-id=axwaydemo \
                         --pass-file=/home/axway/Desktop/password/domainpass.txt \
                         --O=Axway --OU=axwaydemo --C=SG || true
}

build_base_image() {
    echo
    echo "******************************************************************"
    echo "*** Building base image for Admin Node Manager and API Gateway ***"
    echo "******************************************************************"
    $EMT_HOME/build_base_image.py --installer=$APIGW_INSTALLER --os=centos7
}

build_anm_image() {
    echo
    echo "**********************************************************"
    echo "*** Building and starting Admin Node Manager container ***"
    echo "**********************************************************"
    $EMT_HOME/build_anm_image.py --domain-cert=$EMT_HOME/certs/axwaydemo/axwaydemo-cert.pem \
                                 --domain-key=$EMT_HOME/certs/axwaydemo/axwaydemo-key.pem \
                                 --domain-key-pass-file=$PASS_DIR/domainpass.txt \
                                 --anm-username=admin \
                                 --anm-pass-file=$PASS_DIR/anm-pass.txt \
				 --metrics \
				 --merge-dir="$GW_MERGE_DIR"

    docker run -d --name=anm --network=api-gateway-domain \
               -p 8090:8090 \
               -v $EVENTS_DIR:/opt/Axway/apigateway/events \
               -v $ANM_TRACE_DIR:/opt/Axway/apigateway/trace \
               $METRICS_ENV_VARS \
               admin-node-manager
}

build_analytics_image() {
    echo
    echo "*************************************************************"
    echo "*** Building and starting API Gateway Analytics container ***"
    echo "*************************************************************"
    $EMT_HOME/build_aga_image.py --license=$LICENSE_ANA --installer=$APIGW_INSTALLER --os=centos7 \
                                 --analytics-username=user1 \
                                 --analytics-pass-file=$PASS_DIR/userpass.txt \
                                 --analytics-port=8040 \
                                 --metrics-db-url=jdbc:mysql://metricsdb:3306/metrics \
                                 --metrics-db-username=root \
                                 --metrics-db-pass-file=$PASS_DIR/dbpass.txt \
                                 --reports-dir=/tmp/reports \
                                 --email-reports \
                                 --email-to=john@test.com \
                                 --email-from=admin@test.com \
                                 --smtp-conn-type=NONE \
                                 --smtp-host=A16640 \
                                 --smtp-port=25 \
                                 --smtp-username=admin@test.com \
                                 --smtp-pass-file=$PASS_DIR/smtppass.txt \
                                 --merge-dir="$AGA_MERGE_DIR"

    docker run -d --name=analytics --network=api-gateway-domain \
               -p 8040:8040 \
               -v $REPORTS_DIR:/tmp/reports \
               -v $AGA_TRACE_DIR:/opt/Axway/analytics/trace \
               $METRICS_ENV_VARS apigw-analytics
}

build_gateway_image() {
    echo
    echo "***************************************************"
    echo "*** Building and starting API Gateway container ***"
    echo "***************************************************"
    $EMT_HOME/build_gw_image.py --license=$LICENSE \
                                --factory-fed \
                                --out-image=apigateway1-demo \
                                --group-id=demo \
                                --domain-cert=$EMT_HOME/certs/axwaydemo/axwaydemo-cert.pem \
                                --domain-key=$EMT_HOME/certs/axwaydemo/axwaydemo-key.pem \
                                --domain-key-pass-file=$PASS_DIR/domainpass.txt \
                                --merge-dir="$GW_MERGE_DIR"

    docker run -d --name=apigw \
               -v $EVENTS_DIR:/opt/Axway/apigateway/events \
               -v $GW_TRACE_DIR:/opt/Axway/apigateway/groups/emt-group/emt-service/trace \
               -v $RT_MERGE_GW1:/merge/apigateway \
               -e EMT_ANM_HOSTS=anm:8090 \
               -p 8080:8080 \
               -e EMT_DEPLOYMENT_ENABLED=true \
               -e EMT_TRACE_LEVEL=DEBUG \
               $METRICS_ENV_VARS \
               --network=api-gateway-domain apigateway1-demo
}

build_apimanager_image() {
    echo
    echo "***************************************************"
    echo "*** Building and starting API Manager container ***"
    echo "***************************************************"
   $EMT_HOME/build_gw_image.py --license=$LICENSE \
				--fed=/home/axway/Desktop/docker-apimanager.fed \
				--fed-pass-file=$PASS_DIR/fedpass.txt \
                                --out-image=apimanager1-mgr \
                                --group-id=mgr \
                                --domain-cert=$EMT_HOME/certs/axwaydemo/axwaydemo-cert.pem \
                                --domain-key=$EMT_HOME/certs/axwaydemo/axwaydemo-key.pem \
                                --domain-key-pass-file=$PASS_DIR/domainpass.txt \
                                --merge-dir="$MGR_MERGE_DIR" \

    docker run -d --name=apimgr \
               --network=api-gateway-domain \
               -p 8075:8075 -p 8065:8065 -p 8089:8089 \
               -v $EVENTS_DIR:/opt/Axway/apigateway/events \
               -v $MGR_TRACE_DIR:/opt/Axway/apigateway/groups/emt-group/emt-service/trace \
               -v $RT_MERGE_MGR1:/merge/apigateway \
               -e EMT_ANM_HOSTS=anm:8090 \
               -e EMT_DEPLOYMENT_ENABLED=true \
               -e EMT_TRACE_LEVEL=DEBUG \
               $METRICS_ENV_VARS \
               apimanager1-mgr
}

finish() {
    echo
    echo "************"
    echo "*** Done ***"
    echo "************"
    echo 
    echo "Wait a couple of minutes for startup to complete."
    echo
    echo "Login to API Gateway Manager at https://localhost:8090 (admin/admin)"
    echo "Login to API Manager at https://localhost:8075 (apiadmin/password)"
    echo "Login to API Gateway Analytics at https://localhost:8040 (user1/password)"
}

cleanup
setup
build_base_image
build_anm_image
build_analytics_image
build_gateway_image
build_apimanager_image
finish
