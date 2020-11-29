#!/bin/bash
green="\033[32m"
blue="\033[36m"
red="\033[31m"
font="\033[0m"
# 安装Socat
if [ ! -x /usr/bin/socat ] ; then 
	apt install socat
fi
# 安装wget
if [ ! -x /usr/bin/wget ] ; then 
	apt install wget
fi
# 安装unzip
if [ ! -x /usr/bin/unzip ] ; then 
    apt install unzip
fi
# 安装并执行证书签发程序
if [ ! -f /root/.acme.sh/acme.sh ] ; then 
	curl https://get.acme.sh | sh
fi
# 设置权限
source ~/.bashrc

echo ${blue}
read -p "请输入域名(eg:ss.demo.com):" domain
echo ${font}
# 获取本机IP
localh_ip=$(curl https://api-ipv4.ip.sb/ip)
# 获取域名解析IP
domain_ip=$(ping "${domain}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
#
echo "${green}域名dns解析IP${font}: ${domain_ip}"
#
if [ "$localh_ip" = "$domain_ip" ]; then
	echo "${green}域名解析成功! ${font}"
else
	echo "{$red}域名解析失败. 程序终止运行!{$font}"
	exit
fi
#
echo "${blue}开始申请证书.${font}"
~/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force
#
mkdir ~/ssl
# 安装证书
~/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath ~/ssl/ca.crt --keypath ~/ssl/ca.key --ecc --force
echo "${blue}证书安装中. 请稍等...${font}"
sleep 3


wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.8.2/trojan-go-linux-amd64.zip
unzip trojan-go-linux-amd64.zip -d ./trojan
cd trojan && cp example/server.yaml ./ && cp example/trojan-go.service /etc/systemd/system/






