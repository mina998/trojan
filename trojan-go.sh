#!/bin/bash
Green="\033[32m"
Blue="\033[36m"
Red="\033[31m"
Font="\033[0m"

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

echo ${Blue}
read -p "请输入域名(eg:ss.demo.com):" domain
echo ${Font}
# 获取本机IP
localh_ip=$(curl https://api-ipv4.ip.sb/ip)
# 获取域名解析IP
domain_ip=$(ping "${domain}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
#
echo "${Green}域名dns解析IP${Font}: ${domain_ip}"
#
if [ "$localh_ip" = "$domain_ip" ]; then
	echo "${Green}域名解析成功! ${Font}"
else
	echo "{$Red}域名解析失败.程序终止!${Font}"
	exit
fi
#
echo "${Blue}开始申请证书.${Font}"
~/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force
#
mkdir ~/ssl
# 安装证书
~/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath ~/ssl/ca.crt --keypath ~/ssl/ca.key --ecc --force

echo "${Blue}证书安装中. 请稍等...${Font}"
sleep 3
#
echo "${Blue}安装caddy程序${Font}"
apt install nginx
#
echo "${Blue}安装trojan程序${Font}"
# 下载trojan-gfw
wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.8.2/trojan-go-linux-amd64.zip
# 解压缩
unzip trojan-go-linux-amd64.zip -d ./trojan && rm trojan-go-linux-amd64.zip && cd ./trojan

echo $Blue
read -p "请输入密码:" password
echo $Font
# 添加trojan配置文件
cat > config.yaml <<EOF
run-type: server
local-addr: 0.0.0.0
local-port: 443
remote-addr: 127.0.0.1
remote-port: 80
password:
  - ${password}
ssl:
  cert: /root/ssl/ca.crt
  key: /root/ssl/ca.key
  sni: ${domain}
  session_ticket: true
  fingerprint: chrome
mux:
  enabled: true
  concurrency: 8
  idle_timeout: 60
router:
  enabled: true
  block:
    - 'geoip:private'
  geoip: /root/trojan/geoip.dat
  geosite: /root/trojan/geosite.dat
EOF

# 安装trojan服务
cat > /etc/systemd/system/trojan-go.service <<EOF
[Unit]
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/root/trojan/trojan-go -config /root/trojan/config.yaml
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start trojan-go
systemctl enable trojan-go

echo "${Green}查看状态${Font}: ${Blue}systemctl status trojan-go${Font}"
echo "${Green}停　　止${Font}: ${Blue}systemctl stop trojan-go${Font}"
echo "${Green}启　　动${Font}: ${Blue}systemctl restart trojan-go${Font}"

echo "${Blue}服务器地址${Font}: ${Red}${domain}${Font}"
echo "${Blue}端　　　口${Font}: ${Red}443${Font}"
echo "${Blue}密　　　码${Font}: ${Red}${password}${Font}"
echo "${Blue}传输层加密${Font}: ${Red}tls${Font}"