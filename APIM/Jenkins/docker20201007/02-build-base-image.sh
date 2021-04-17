#!/bin/sh

# Halt on error
set -e
APIGW_INSTALLER=/var/jenkins_home/docker20201007/APIGateway_7.7.20200730_Install_linux-x86-64_BN02.run
LICENSE=/var/jenkins_home/docker20201007/lic.lic
LICENSE_ANA=/var/jenkins_home/docker20201007/analytics.lic
MYSQL_JDBC_JAR=/var/jenkins_home/docker20201007/mysql-connector-java-5.1.47.jar
EMT_HOME=/var/jenkins_home/docker20201007/apigw-emt-scripts-2.1.0-SNAPSHOT
EMT_DIR=/var/jenkins_home/docker20201007/emt-tmp
FROM_CONTAINER=/var/jenkins_home/docker20201007/from-containers
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
PASS_DIR=/var/jenkins_home/docker20201007/password
RT_MERGE_DIR=/var/jenkins_home/docker20201007/runtime-merge
RT_MERGE_GW1=$RT_MERGE_DIR/apigateway1/apigateway
RT_MERGE_MGR1=$RT_MERGE_DIR/apimanager1/apigatway

METRICS_ENV_VARS="-e METRICS_DB_URL=jdbc:mysql://mysql:3306/Axway?useSSL=false -e METRICS_DB_USERNAME=apigateway -e METRICS_DB_PASS=changeme"


build_base_image() {
    echo
    echo "******************************************************************"
    echo "*** Building base image for Admin Node Manager and API Gateway ***"
    echo "******************************************************************"
    $EMT_HOME/build_base_image.py --installer=$APIGW_INSTALLER --os=centos7
}

finish() {
    echo
    echo "************"
    echo "***Step2 Done ***"
    echo "************"
}

build_base_image
finish
