#!/bin/sh

# 申请泛域名证书
Blue="\033[36m"
Font="\033[0m"

# 安装Socat
if [ ! -x /usr/bin/socat ] ; then 
	apt install socat
fi
# 下载证书签发程序
if [ ! -f "/root/.acme.sh/acme.sh" ] ; then 
	curl https://get.acme.sh | sh
fi
# 
echo ${Blue}
read -p "请输入域名(eg:demo.com):" domain
echo ${Font}
# 获取本机IP
localh_ip=$(curl https://api-ipv4.ip.sb/ip)
# 获取域名解析IP
domain_ip=$(ping "${domain}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')

if [ "$localh_ip" = "$domain_ip" ];then
	echo "${Blue}域名dns解析IP${Font}: ${domain_ip}"
else
	echo "${Blue}域名解析失败.${Font}"
	exit 2
fi

echo ${Blue}
read -p "请输入Dnspod ID:" id
export DP_Id=$id
read -p "请输入Dnspod KEY:" key
export DP_Key=$key
echo ${Font}

~/.acme.sh/acme.sh --issue --dns dns_dp -d ${domain} -d *.${domain} -k ec-256 --force
rm -rf ~/certificate
mkdir ~/certificate
~/.acme.sh/acme.sh --installcert -d ${domain} --fullchainpath ~/certificate/ca.crt --keypath ~/certificate/ca.key --ecc --force


