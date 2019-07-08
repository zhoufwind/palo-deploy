#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

#################################################################################
# This script is used to upgrade Apache Doris(incubating) apache_hdfs_broker
#
# Usage:
#    sh upgrade-fs_brokers.sh palo /usr/local/src/output /data/palo_fe_log /home/soft/java
#
# You need acknowledge following items before run it:
#   - Execute this script by root account;
#   - Java have been installed previously;
#   - Supervisor have been installed previously;
#################################################################################

# Usage
Usage() {
    echo "upgrade-fs_brokers.sh [fb_owner] [fb_output_path] [fb_log_path] [java_home]"
    echo "Eg: sh upgrade-fs_brokers.sh palo /usr/local/src/output /data/palo_hdfs_broker_log /home/soft/java"
    return 0
}

# Check input parameters
if [ $# -eq 1 ]; then
    if [ "$1" = "-h" ]; then
        Usage
        exit 0
    else
        Usage
        exit -1
    fi
elif [ $# -ne 4 ]; then
    Usage
    exit -1
fi

# Backup apache_hdfs_broker directory
echo "Backup apache_hdfs_broker directory..."
mv /home/$1/apache_hdfs_broker /home/$1/apache_hdfs_broker.bak-$(date +%F)

# Initial apache_hdfs_broker directory
echo "Initial apache_hdfs_broker directory..."
mkdir /home/$1/apache_hdfs_broker -pv
cp -rf $2/apache_hdfs_broker/* /home/$1/apache_hdfs_broker/
chown -R $1:$1 /home/$1/

# Build apache_hdfs_broker log softlink
echo "Build apache_hdfs_broker log softlink..."
ln -s $3 /home/$1/apache_hdfs_broker/log
chown $1:$1 /home/$1/apache_hdfs_broker/log

# Modify apache_hdfs_broker bin file
echo "Modify apache_hdfs_broker bin file..."
cp -rf /home/$1/apache_hdfs_broker/bin/start_broker.sh /home/$1/apache_hdfs_broker/bin/start_broker_hup.sh
chown $1:$1 /home/$1/apache_hdfs_broker/bin/start_broker_hup.sh
sed -i "s,/dev/null &,/dev/null,g" /home/$1/apache_hdfs_broker/bin/start_broker_hup.sh
sed -i "/export JAVA_OPTS/i export JAVA_HOME=$4" /home/$1/apache_hdfs_broker/bin/start_broker_hup.sh
