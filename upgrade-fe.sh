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
# This script is used to upgrade Apache Doris(incubating) Frontend
#
# Usage:
#    sh upgrade-fe.sh palo /usr/local/src/output /data/palo_fe_log /home/soft/java
#
# You need acknowledge following items before run it:
#   - Execute this script by root account;
#   - Java have been installed previously;
#   - Supervisor have been installed previously;
#################################################################################

# Usage
Usage() {
    echo "upgrade-fe.sh [fe_owner] [palo_output_path] [fe_log_path] [java_home]"
    echo "Eg: sh upgrade-fe.sh palo /usr/local/src/output /data/palo_fe_log /home/soft/java"
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

# Backup FE directory
echo "Backup FE directory..."
mv /home/$1/fe /home/$1/fe.bak-$(date +%F)

# Initial FE directory
echo "Initial FE directory..."
mkdir /home/$1/fe -pv
cp -rf $2/fe/* /home/$1/fe/
chown -R $1:$1 /home/$1/

# Copy FE metadata directory
echo "Copy FE metadata directory..."
mkdir /home/$1/fe/palo-meta
cp -rf /home/$1/fe.bak-$(date +%F)/palo-meta/* /home/$1/fe/palo-meta/
chown -R $1:$1 /home/$1/

# Build FE log softlink
echo "Build FE log softlink..."
ln -s $3 /home/$1/fe/log
chown $1:$1 /home/$1/fe/log

# Modify FE conf
echo "Modify FE conf file..."
cp -rf /home/$1/fe/conf/fe.conf /home/$1/fe/conf/fe.conf.src
chown $1:$1 /home/$1/fe/conf/fe.conf.src
echo "JAVA_HOME = $4" >> /home/$1/fe/conf/fe.conf
echo "tablet_create_timeout_second = 4" >> /home/$1/fe/conf/fe.conf
sed -i "s,-Xmx4096m,-Xmx8G,g" /home/$1/fe/conf/fe.conf
sed -i "s,edit_log_port = 9010,edit_log_port = 9011,g" /home/$1/fe/conf/fe.conf

# Modify FE bin file
echo "Modify FE bin file..."
cp -rf /home/$1/fe/bin/start_fe.sh /home/$1/fe/bin/start_fe_hup.sh
chown $1:$1 /home/$1/fe/bin/start_fe_hup.sh
sed -i "s,/dev/null &,/dev/null,g" /home/$1/fe/bin/start_fe_hup.sh

# Modify token and clusterId
echo "Modify token and clusterId: /home/$1/fe/palo-meta/image/VERSION"
cat /home/$1/fe/palo-meta/image/VERSION