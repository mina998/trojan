#!/bin/sh
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
# 安装并执行证书签发程序
if [ ! -f /root/.acme.sh/acme.sh ] ; then 
	curl https://get.acme.sh | sh
fi
# 设置权限
source ~/.bashrc

echo ${Blue}
read -p "请输入域名(ss.demo.com):" domain
echo ${Font}

localh_ip=$(curl https://api-ipv4.ip.sb/ip)
domain_ip=$(ping "${domain}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')

echo "${Green}域名dns解析IP${Font}: ${domain_ip}"

if [ "$localh_ip" = "$domain_ip" ]; then
	echo "${Green}域名解析成功! ${Font}"
else
	echo "{$Red}域名解析失败.是否继续安装(y|N)${Font}" && read -r install
	case $install in
		[yY][eE][sS] | [yY])
            sleep 2
			;;
		*)
			echo "${Red}安装终止${Font}"
            exit 2
			;;	
	esac
fi

echo "${Blue}开始申请证书.${Font}"
~/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force
#
mkdir ~/ssl
# 安装证书
~/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath ~/ssl/ca.crt --keypath ~/ssl/ca.key --ecc --force

echo "${Blue}证书安装中. 请稍等...${Font}"
sleep 3

# 下载trojan-gfw
wget https://github.com/trojan-gfw/trojan/releases/download/v1.16.0/trojan-1.16.0-linux-amd64.tar.xz
# 解压缩
tar vxf trojan-1.16.0-linux-amd64.tar.xz  && rm trojan-1.16.0-linux-amd64.tar.xz
# 删除多余文件
cd trojan && rm CONTRIBUTORS.md LICENSE README.md

echo $Blue
read -p "请输入密码:" password
echo $Font
# 添加trojan配置文件
cat > config.json <<EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "${password}"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/root/ssl/ca.crt",
        "key": "/root/ssl/ca.key",
        "key_password": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "alpn_port_override": {
            "h2": 81
        },
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "prefer_ipv4": false,
        "no_delay": true,
        "keep_alive": true,
        "reuse_port": false,
        "fast_open": false,
        "fast_open_qlen": 20
    }
}
EOF

# 安装trojan服务
cat > /etc/systemd/system/trojan.service <<EOF
[Unit]
Description=trojan
Documentation=man:trojan(1) https://trojan-gfw.github.io/trojan/config https://trojan-gfw.github.io/trojan/
After=network.target network-online.target nss-lookup.target
[Service]
Type=simple
StandardError=journal
User=root
AmbientCapabilities=CAP_NET_BIND_SERVICE
ExecStart=/root/trojan/trojan -c /root/trojan/config.json
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=1s
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start trojan
systemctl enable trojan

# 下载Caddy
wget https://github.com/caddyserver/caddy/releases/download/v2.2.1/caddy_2.2.1_linux_amd64.deb
# 安装Caddy
dpkg -i caddy_2.2.1_linux_amd64.deb && rm caddy_2.2.1_linux_amd64.deb

echo ${Blue}
read -p "请输入伪装网站(https://www.qb5.tw):" web2
echo ${Font}

# 添加Caddy配置文件
cd /etc/caddy/ && cat > Caddyfile <<EOF
:80
reverse_proxy ${web2} {
    header_up Host {http.reverse_proxy.upstream.hostport}
}
EOF
# 重启Caddy
caddy stop && caddy start && cd ~

echo "${Blue}服务器地址${Font}: ${Red}${domain}${Font}"
echo "${Blue}端　　　口${Font}: ${Red}443${Font}"
echo "${Blue}密　　　码${Font}: ${Red}${password}${Font}"
echo "${Blue}传输层加密${Font}: ${Red}tls${Font}"

echo "${Green}查看状态${Font}: ${Blue}systemctl status trojan${Font}"
echo "${Green}停　　止${Font}: ${Blue}systemctl stop trojan${Font}"
echo "${Green}启　　动${Font}: ${Blue}systemctl restart trojan${Font}"
