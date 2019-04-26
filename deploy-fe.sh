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
# This script is used to deploy Apache Doris(incubating) Frontend
#
# Usage:
#    sh deploy-fe.sh palo /usr/local/src/output /data/palo_fe_log /home/soft/java
#
# You need acknowledge following items before run it:
#   - Execute this script by root account;
#   - Java have been installed previously;
#   - Supervisor have been installed previously;
#################################################################################

# Usage
Usage() {
    echo "deploy-fe.sh [fe_owner] [palo_output_path] [fe_log_path] [java_home]"
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

# Confirm FE parameters
echo "FE settings:"
echo "fe_owner: $1"
echo "palo_output_path: $2"
echo "fe_log_path: $3"
echo "java_home: $4"
read -p "If continue, press y..." -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

# Add FE owner
echo "Add FE owner..."
useradd $1

# Initial FE directory
echo "Initial FE directory..."
mkdir /home/$1/fe -pv
cp -rf $2/fe/* /home/$1/fe/
chown -R $1:$1 /home/$1/

# Initial FE metadata directory
echo "Initial FE metadata directory..."
mkdir /home/$1/fe/palo-meta
chown -R $1:$1 /home/$1/

# Initial FE log directory
echo "Initial FE log directory..."
mkdir $3 -pv
chown -R $1:$1 $3

# Build FE log softlink
echo "Build FE log softlink..."
ln -s $3 /home/$1/fe/log
chown $1:$1 /home/$1/fe/log

# Modify FE conf
echo "Modify FE conf file..."
cp -rf /home/$1/fe/conf/fe.conf /home/$1/fe/conf/fe.conf.src
chown $1:$1 /home/$1/fe/conf/fe.conf.src
echo "JAVA_HOME = $4" >> /home/$1/fe/conf/fe.conf

# Modify FE bin file
echo "Modify FE bin file..."
cp -rf /home/$1/fe/bin/start_fe.sh /home/$1/fe/bin/start_fe_hup.sh
chown $1:$1 /home/$1/fe/bin/start_fe_hup.sh
sed -i "s,/dev/null &,/dev/null,g" /home/$1/fe/bin/start_fe_hup.sh

# Add FE settings to supervisor file
echo "Update FE settings to supervisor conf..."
cat << EOF >> /etc/supervisord.d/palo.conf
[program:palo_fe]
command=/home/$1/fe/bin/start_fe_hup.sh
user=palo
directory=/home/$1
stopsignal=INT
stopasgroup=true
killasgroup=true
log_stderr=true
stdout_logfile=/home/$1/fe/log/fe.log
stderr_logfile=/home/$1/fe/log/fe.log

EOF

# Add FE supervisor log
echo "Add FE supervisor log..."
touch /home/$1/fe/log/fe.log
chown $1:$1 /home/$1/fe/log/fe.log

# Reload supervisor
echo "reload supervisor..."
supervisorctl reload

# Show supervisor status
sleep 2
echo "show supervirsor status..."
supervisorctl status

