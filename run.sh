#!/bin/bash

set -e
user=$(env | grep USER | cut -d "=" -f 2)
SELFPATH=$(cd "$(dirname "$0")"; pwd)
NGROK_DOMAIN="ngrok.bluarry.top"

# 判断当前用户是否是root
SUDOF="sudo"
if [ "$user" == "root" ]
   then
     SUDOF=""
fi 

# 首先准备环境
$SUDOF apt-get update
$SUDOF apt-get -y --force-yes install build-essential  mercurial git


# 接下来安装go环境

#删除旧的go
$SUDOF rm -rf /usr/local/go
$SUDOF rm -rf /usr/bin/go
$SUDOF rm -rf /usr/bin/godoc
$SUDOF rm -rf /usr/bin/gofmt

# 判断下载go
ldconfig

cd $SELFPATH
# 动态链接库，用于下面的判断条件生效
ldconfig
# 判断操作系统位数下载不同的安装包
if [ $(getconf WORD_BIT) = '32' ] && [ $(getconf LONG_BIT) = '64' ];then
	# 判断文件是否已经存在
	if [ ! -f $SELFPATH/go1.7.6.linux-amd64.tar.gz ];then
		wget http://mirrors.ustc.edu.cn//golang/go1.9.linux-amd64.tar.gz --no-check-certificate
	fi	
          tar zxvf go1.9.linux-amd64.tar.gz
	else
		if [ ! -f $SELFPATH/go1.7.6.linux-386.tar.gz ];then
		wget http://mirrors.ustc.edu.cn//golang/go1.9.linux-386.tar.gz --no-check-certificate
		fi
	    tar zxvf go1.9.linux-386.tar.gz
	fi
$SUDOF mv go /usr/local/
$SUDOF ln -s /usr/local/go/bin/* /usr/bin/


# 编译安装ngork

cd $SELFPATH

git clone https://github.com/bluarry/ngrok.git
cd ngrok/

openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$NGROK_DOMAIN" -days 5000 -out rootCA.pem
openssl genrsa -out device.key 2048
openssl req -new -key device.key -subj "/CN=$NGROK_DOMAIN" -out device.csr
openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 5000
cp rootCA.pem assets/client/tls/ngrokroot.crt
cp device.crt assets/server/tls/snakeoil.crt 
cp device.key assets/server/tls/snakeoil.key

make release-server

# 将服务端的安装
$SUDOF mv bin/ngrokd /usr/local/
$SUDOF ln -s /usr/local/ngrokd /usr/bin/ngrokd




# 编译各种客户端

# 同环境下的客户端
make release-client

cd /usr/local/go/src
GOOS=windows GOARCH=amd64 ./make.bash
cd -
GOOS=windows GOARCH=amd64 make release-client
GOOS=linux GOARCH=amd64 make release-client

mkdir -p ~/ngrok_client

cp -r bin/* ~/ngrok_client/



echo "ngrokd服务端安装完成"
echo "ngrok 客户端编译完成"

