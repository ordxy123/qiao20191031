#!/bin/bash

#集群节点（一台机器安装多个节点，端口不同）
#ip:7001
#ip:7002
#ip:7003
#ip:7004
#ip:7005
#ip:7006
#...

#默认 root 权限登录

#redis下载链接,版本为4.0.9
redisUrl='http://download.redis.io/releases/redis-4.0.9.tar.gz'

#判断系统类型 yum/apt
#if [ $(cat /etc/redhat-release | grep CentOS)];then

#判断系统版本

#下载redis
#判断 wget 是否安装
if [ $(rpm -qa | grep wget) == "" ];then
#根据系统类型和版本判断执行命令；暂时不会写
	yum -y install wget	
fi

wget $redisUrl -O redis.tar.gz

#解压
#判断 tar 是否安装
if [ $(rpm -qa | grep tar) == "" ];then
#根据系统类型和版本判断执行命令
	yum -y install tar	
fi

tar -zxvf redis.tar.gz
mv $(ls | grep redis-) redis

#编译安装
#需要判断 c 环境是否搭建
cd redis/
make && make install

#
cd src/
cp redis-trib.rb /usr/local/bin/

#
mkdir -p /opt/redis/redis_cluster
cp ../redis.conf /opt/redis/redis_cluster/

#复制redis.conf配置文件命名为redis-7001.conf，redis-7002.conf，redis-7003.conf，redis-7004.conf，redis-7005.conf，redis-7006.conf
cd /opt/redis/redis_cluster/
#设置需要配置redis的个数
num=7
#复制
#配置文件命名拼接字符串
pre='redis.700'
after='.conf'
for(i = 0; i < $num; i++));
do
cp redis.conf $pre$i$after
done

#修改配置文件
#获取本机ip地址
#ip=ifconfig eth0 | grep "inet addr" | awk '{ print $2}' | awk -F: '{print $2}'
ip=192.168.2.131
#使用python修改配置文件
#获取python路径
pythonBin=$(which python)

#python实现配置文件的修改
#shell中执行python暂时不会；python代码未测试；redis个数for i 循环未传入；ip未传入
def funChange(oldText, newText, i){
data = ''
with open('redis700' + i + '.conf', 'r+') as f:
  for line in f.readlines():
    if(line.find('oldText') == 0):
      line = 'newText'
    data += line
with open('redis700' + i + '.conf', 'r+') as f:
  f.writelines(data)
}

def funmain(){
        oldText = ['bind 127.0.0.1', 'daemonize no', 'pidfile', 'cluster-enabled', 'cluster-config-file', 'cluster-node-timeout', 'appendonly yes', 'port 6379']
        newText = ['bind 192.168.2.131', 'daemonize yes', 'pidfile /var/run/redis_700', 'cluster-enabled yes', 'cluster-config-file nodes_700', 'cluster-node-timeout 15000', 'appendonly yes', 'port 7001']
        for i in range(1, 8):
                newText[2] += i + '.pid';
                newText[4] += i + '.conf';
                for j in range(0, 8):
                        funChange(oldText[j], newText[j], i);
funmain();

#启动redis
cd /opt/redis/redis_cluster/
for(i = 0; i < $num; i++));
do
redis-server $pre$i$after
done

#需要判断端口是否启用

#安装依赖工具
yum -y install ruby ruby-devel rubygems rpm-build
gem install redis

#安装是否报错：redis requires Ruby version >= 2.2.2的报错

#报错则执行;
#判断是否安装 curl
if [ $(rpm -qa | grep curl) == "" ];then
#根据系统类型和版本判断执行命令；暂时不会写
	yum -y install curl	
fi
#安装 rvm；报错：curl: (6) Couldn't resolve host 'get.rvm.io'选择第二条执行
curl -L get.rvm.io | bash -s stable 
#curl -L https://raw.githubusercontent.com/wayneeseguin/rvm/master/binscripts/rvm-installer | bash -s stable
#报错，加入秘钥；后续再执行一次 curl -L get.rvm.io | bash -s stable
#gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

#source环境，让rvm可用
source /usr/local/rvm/scripts/rvm

#安装ruby 2.3.4
rvm install 2.3.4

#使用一个ruby版本
rvm use 2.3.4

#安装ruby访问redis的驱动
gem install redis

#创建redis集群
str=':700'
portPre=$ip$str
for(i = 0; i < $num; i++));
do
redis-trib.rb create --replicas 1 $portPre$i
done

#连接集群
#redis-cli -h ip -c -p port
