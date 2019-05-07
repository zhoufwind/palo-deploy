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
# This script is used to upgrade Apache Doris(incubating) Backend
#
# Usage:
#    sh upgrade-be.sh 1 /data1/palo palo /usr/local/src/output /data1/palo_be_log
#
# You need acknowledge following items before run it:
#   - Execute this script by root account;
#   - Supervisor have been installed previously;
#################################################################################

# Usage
Usage() {
    echo "upgrade-be.sh [be_id] [be_data_path] [be_owner] [palo_output_path] [be_log_path]"
    echo "Eg: sh upgrade-be.sh 1 /data1/palo palo /usr/local/src/output /data1/palo_be_log"
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
elif [ $# -ne 5 ]; then
    Usage
    exit -1
fi

# Check `be_id` is number
re='^[0-9]$'
if ! [[ $1 =~ $re ]]; then
    echo "error: [be_id] should be number between 0~9!" >&2;
    exit 1
fi

# Backup BE directory
echo "Backup BE directory..."
mv /home/$3/be$1 /home/$3/be$1.bak-$(date +%F)

# Initial BE directory
echo "Initial BE directory..."
mkdir /home/$3/be$1 -pv
cp -rf $4/be/* /home/$3/be$1/
chown -R $3:$3 /home/$3/

# Build BE log softlink
echo "Build BE log softlink..."
ln -s $5 /home/$3/be$1/log
chown $3:$3 /home/$3/be$1/log

# Modify BE conf file
echo "Modify BE conf file..."
cp -rf /home/$3/be$1/conf/be.conf /home/$3/be$1/conf/be.conf.src
chown $3:$3 /home/$3/be$1/conf/be.conf.src
sed -i "s,be_port = 9060,be_port = 906$1,g" /home/$3/be$1/conf/be.conf
sed -i "s,be_rpc_port = 9070,be_rpc_port = 907$1,g" /home/$3/be$1/conf/be.conf
sed -i "s,webserver_port = 8040,webserver_port = 804$1,g" /home/$3/be$1/conf/be.conf
sed -i "s,heartbeat_service_port = 9050,heartbeat_service_port = 905$1,g" /home/$3/be$1/conf/be.conf
sed -i "s,brpc_port = 8060,brpc_port = 806$1,g" /home/$3/be$1/conf/be.conf
sed -i "s,/home/disk1/palo;/home/disk2/palo,$2,g" /home/$3/be$1/conf/be.conf
echo "mem_limit = 30%" >> /home/$3/be$1/conf/be.conf

# Modify BE bin file
echo "Modify BE bin file..."
cp -rf /home/$3/be$1/bin/start_be.sh /home/$3/be$1/bin/start_be_hup.sh
chown $3:$3 /home/$3/be$1/bin/start_be_hup.sh
sed -i "s,/dev/null &,/dev/null,g" /home/$3/be$1/bin/start_be_hup.sh