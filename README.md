# palo-deploy
使用shell脚本部署Apache Doris (incubating)（原百度palo）

## 快速部署

1. 安装`java`环境

- 查询jdk下载地址：

```bash
curl -s https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html|grep linux-x64.rpm
```

- 复制`filepath`地址，浏览器中进行访问，完成登录验证后进行下载，下载完毕后进行安装：

```bash
rpm -ivh jdk-8u211-linux-x64.rpm 
ls -ld /usr/java/jdk1.8.0_211-amd64/
ln -s /usr/java/jdk1.8.0_211-amd64 /usr/java/jdk
echo "export JAVA_HOME=/usr/java/jdk" >> /etc/profile
echo "export JRE_HOME=/usr/java/jdk/jre" >> /etc/profile
```

2. 安装`supervisor`环境

```bash
yum install supervisor -y
echo "files = supervisord.d/*.conf" >> /etc/supervisord.conf
systemctl enable supervisord
systemctl start supervisord.service
systemctl status supervisord.service
```

注：supervisor主配置文件路径为：`/etc/supervisord.conf`，子配置目录为：`/etc/supervisord.d/`，若配置非标准，需要手工修改部署脚本。

3. 拷贝palo编译完成后output文件至指定目录，如：`/usr/local/src/output`：

```bash
cp -rf /your/local/path/incubator-doris-DORIS-x.x.x-release/output /usr/local/src/output
```

注：在部署集群时，不可能将整个源码+编译文件都拷贝到集群服务器，此时只需打包`output`目录，拷贝至集群各服务器，解压使用：

```bash
# 编译服务器上打包output目录，并上传至ftp
cd /your/local/path/incubator-doris-DORIS-x.x.x-release/
tar zcf output.tar.gz output
curl -s -k -T output.tar.gz output -u <u>:<p> ftp://x.x.x.x//

# 从ftp拷贝打包文件至集群各服务器，并解压
wget -P /usr/local/src/ ftp://<u>:<p>@x.x.x.x:21/output.tar.gz
tar zxf /usr/local/src/output.tar.gz -C /usr/local/src/
```

4. 部署`Frontend`，`root`环境下执行以下命令：

```bash
sh deploy-fe.sh palo /usr/local/src/output /data/palo_fe_log /home/soft/java
```

注：以下参数必须指定后执行，缺一不可：

- palo：以该用户执行palo；
- /usr/local/src/output：palo编译完成后output文件路径；
- /data/palo_fe_log：指定存放FE日志文件路径；
- /home/soft/java：指定JAVA_HOME目录；

5. 部署`Backend`，`root`环境下执行以下命令：

```bash
sh deploy-be.sh 1 /data1/palo palo /usr/local/src/output /data1/palo_be_log
```

注：以下参数必须指定后执行，缺一不可：

- 1：由于同一台服务器有部署多个be的场景，故指定BE ID，注意该id与BE端口相关联，必须在0～9之内；
- /data1/palo：指定存放BE数据文件路径；
- palo：以该用户执行palo；
- /usr/local/src/output：palo编译完成后output文件路径；
- /data1/palo_be_log：指定存放BE日志文件路径；

## 验证服务

- 验证FE集群

```bash
mysql -h <fe_ip> -P 9030 -uroot
ALTER SYSTEM ADD FOLLOWER "<fe_ip>:9010";
show proc '/frontends';
```

- 验证BE集群

```bash
mysql -h <fe_ip> -P 9030 -uroot
ALTER SYSTEM ADD BACKEND "<be_ip>:<be_heartbeat_service_port>";
SHOW PROC '/backends';
```