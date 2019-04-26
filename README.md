# palo-deploy
使用shell脚本部署Apache Doris (incubating)（原百度palo）

# 快速部署

1. 安装`java`环境

- 查询jdk下载地址：

```bash
curl -s https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html|grep linux-x64.rpm
```

- 复制`filepath`地址，浏览器访问并完成身份验证后进行下载；

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

3. 拷贝编译好的output文件至指定目录

```bash
cp -rf /your/local/path/incubator-doris-DORIS-x.x.x-release/output /usr/local/src/output
```

4. 部署`Backend`，`root`环境下执行以下命令：

```bash
sh deploy-be.sh 1 /data1/palo palo /usr/local/src/output /data1/palo_be_log
```

以下参数必须指定后执行，缺一不可：

- 1：由于同一台服务器有部署多个be的场景，故指定BE ID，注意该id与BE端口相关联，必须在0～9之内；
- /data1/palo：指定存放BE数据文件路径；
- /usr/local/src/output：编译好的output文件路径；
- /data1/palo_be_log：指定存放BE日志文件路径；
