#!/bin/bash
# Script by Gun_GZN[GUN-X] 
# @LINE:gzn007
# ขอขอบคุณทีมงานที่ค่อยซัพพอร์ตและให้กำลังใจ

#############################
#############################
# Variables (Can be changed depends on your preferred values)
# Script name
MyScriptName='Gun_GZN'

# OpenSSH Ports
SSH_Port1='22'
SSH_Port2='226'

# Your SSH Banner
SSH_Banner='https://myserver.aj-net.com/ovpnsc/deb9/files/plugins/issue.net'

# Dropbear Ports
Dropbear_Port1='143'
Dropbear_Port2='110'

# Stunnel Ports
Stunnel_Port1='555' # through Dropbear
Stunnel_Port2='444' # through OpenSSH

# OpenVPN Ports
OpenVPN_TCP_Port='443'
OpenVPN_UDP_Port='445'

# Squid Ports
Squid_Port1='3128'
Squid_Port2='8080'
Squid_Port3='8000'

# OpenVPN Config Download Port
OvpnDownload_Port='85' # Before changing this value, please read this document. It contains all unsafe ports for Google Chrome Browser, please read from line #23 to line #89: https://chromium.googlesource.com/chromium/src.git/+/refs/heads/master/net/base/port_util.cc

# Server local time
MyVPS_Time='Asia/Bangkok'
#############################


#############################
#############################
## All function used for this script
#############################
## WARNING: Do not modify or edit anything
## if you did'nt know what to do.
## This part is too sensitive.
#############################
#############################

function InstUpdates(){
 export DEBIAN_FRONTEND=noninteractive
 apt-get update
 apt-get upgrade -y
 
 # Removing some firewall tools that may affect other services
 apt-get remove --purge ufw firewalld -y

 # Install Speedtest
 apt install python-pip
 apt install ptyhon3-pip
 pip install speedtest-cli
 
 # Installing some important machine essentials
 apt-get install nano wget curl zip unzip tar gzip p7zip-full bc rc openssl cron net-tools dnsutils dos2unix screen bzip2 ccrypt -y
 
 # Now installing all our wanted services
 apt-get install dropbear stunnel4 privoxy ca-certificates nginx ruby apt-transport-https lsb-release squid -y

 # Installing all required packages to install Webmin
 apt-get install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python dbus libxml-parser-perl -y
 apt-get install shared-mime-info jq fail2ban -y

 
 # Installing a text colorizer
 gem install lolcat

 # Trying to remove obsolette packages after installation
 apt-get autoremove -y
 
 # Installing OpenVPN by pulling its repository inside sources.list file 
 rm -rf /etc/apt/sources.list.d/openvpn*
 echo "deb http://build.openvpn.net/debian/openvpn/stable $(lsb_release -sc) main" > /etc/apt/sources.list.d/openvpn.list
 wget -qO - http://build.openvpn.net/debian/openvpn/stable/pubkey.gpg|apt-key add -
 apt-get update
 apt-get install openvpn -y
}

function InstWebmin(){
 # Download the webmin .deb package
 # You may change its webmin version depends on the link you've loaded in this variable(.deb file only, do not load .zip or .tar.gz file):
 WebminFile='https://github.com/GunGZN/runvpn2.0/raw/main/webmin_1.920_all.deb'
 wget -qO webmin.deb "$WebminFile"
 
 # Installing .deb package for webmin
 dpkg --install webmin.deb
 
 rm -rf webmin.deb
 
 # Configuring webmin server config to use only http instead of https
 sed -i 's|ssl=1|ssl=0|g' /etc/webmin/miniserv.conf
 
 # Then restart to take effect
 systemctl restart webmin
}

function InstSSH(){
 # Removing some duplicated sshd server configs
 rm -f /etc/ssh/sshd_config*
 
 # Creating a SSH server config using cat eof tricks
 cat <<'MySSHConfig' > /etc/ssh/sshd_config
# My OpenSSH Server config
Port myPORT1
Port myPORT2
AddressFamily inet
ListenAddress 0.0.0.0
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
PermitRootLogin yes
MaxSessions 1024
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
ClientAliveInterval 240
ClientAliveCountMax 2
UseDNS no
Banner /etc/banner
AcceptEnv LANG LC_*
Subsystem   sftp  /usr/lib/openssh/sftp-server
MySSHConfig

 # Now we'll put our ssh ports inside of sshd_config
 sed -i "s|myPORT1|$SSH_Port1|g" /etc/ssh/sshd_config
 sed -i "s|myPORT2|$SSH_Port2|g" /etc/ssh/sshd_config

 # Download our SSH Banner
 rm -f /etc/banner
 wget -qO /etc/banner "$SSH_Banner"
 dos2unix -q /etc/banner

 # My workaround code to remove `BAD Password error` from passwd command, it will fix password-related error on their ssh accounts.
 sed -i '/password\s*requisite\s*pam_cracklib.s.*/d' /etc/pam.d/common-password
 sed -i 's/use_authtok //g' /etc/pam.d/common-password

 # Some command to identify null shells when you tunnel through SSH or using Stunnel, it will fix user/pass authentication error on HTTP Injector, KPN Tunnel, eProxy, SVI, HTTP Proxy Injector etc ssh/ssl tunneling apps.
 sed -i '/\/bin\/false/d' /etc/shells
 sed -i '/\/usr\/sbin\/nologin/d' /etc/shells
 echo '/bin/false' >> /etc/shells
 echo '/usr/sbin/nologin' >> /etc/shells
 
 # Restarting openssh service
 systemctl restart ssh
 
 # Removing some duplicate config file
 rm -rf /etc/default/dropbear*
 
 # creating dropbear config using cat eof tricks
 cat <<'MyDropbear' > /etc/default/dropbear
# My Dropbear Config
NO_START=0
DROPBEAR_PORT=PORT01
DROPBEAR_EXTRA_ARGS="-p PORT02"
DROPBEAR_BANNER="/etc/banner"
DROPBEAR_RSAKEY="/etc/dropbear/dropbear_rsa_host_key"
DROPBEAR_DSSKEY="/etc/dropbear/dropbear_dss_host_key"
DROPBEAR_ECDSAKEY="/etc/dropbear/dropbear_ecdsa_host_key"
DROPBEAR_RECEIVE_WINDOW=65536
MyDropbear

 # Now changing our desired dropbear ports
 sed -i "s|PORT01|$Dropbear_Port1|g" /etc/default/dropbear
 sed -i "s|PORT02|$Dropbear_Port2|g" /etc/default/dropbear
 
 # Restarting dropbear service
 systemctl restart dropbear
}

function InsStunnel(){
 StunnelDir=$(ls /etc/default | grep stunnel | head -n1)

 # Creating stunnel startup config using cat eof tricks
cat <<'MyStunnelD' > /etc/default/$StunnelDir
# My Stunnel Config
ENABLED=1
FILES="/etc/stunnel/*.conf"
OPTIONS=""
BANNER="/etc/banner"
PPP_RESTART=0
# RLIMITS="-n 4096 -d unlimited"
RLIMITS=""
MyStunnelD

 # Removing all stunnel folder contents
 rm -rf /etc/stunnel/*
 
 # Creating stunnel certifcate using openssl
 openssl req -new -x509 -days 9999 -nodes -subj "/C=PH/ST=NCR/L=Kuala_Lumpur/O=$MyScriptName/OU=$MyScriptName/CN=$MyScriptName" -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem &> /dev/null
##  > /dev/null 2>&1

 # Creating stunnel server config
 cat <<'MyStunnelC' > /etc/stunnel/stunnel.conf
# My Stunnel Config
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
TIMEOUTclose = 0
[dropbear]
accept = Stunnel_Port1
connect = 127.0.0.1:dropbear_port_c
[openssh]
accept = Stunnel_Port2
connect = 127.0.0.1:openssh_port_c
MyStunnelC

 # setting stunnel ports
 sed -i "s|Stunnel_Port1|$Stunnel_Port1|g" /etc/stunnel/stunnel.conf
 sed -i "s|dropbear_port_c|$(netstat -tlnp | grep -i dropbear | awk '{print $4}' | cut -d: -f2 | xargs | awk '{print $2}' | head -n1)|g" /etc/stunnel/stunnel.conf
 sed -i "s|Stunnel_Port2|$Stunnel_Port2|g" /etc/stunnel/stunnel.conf
 sed -i "s|openssh_port_c|$(netstat -tlnp | grep -i ssh | awk '{print $4}' | cut -d: -f2 | xargs | awk '{print $2}' | head -n1)|g" /etc/stunnel/stunnel.conf

 # Restarting stunnel service
 systemctl restart $StunnelDir

}

function InsOpenVPN(){
 # Checking if openvpn folder is accidentally deleted or purged
 if [[ ! -e /etc/openvpn ]]; then
  mkdir -p /etc/openvpn
 fi

 # Removing all existing openvpn server files
 rm -rf /etc/openvpn/*

 # Creating server.conf, ca.crt, server.crt and server.key
 cat <<'myOpenVPNconf' > /etc/openvpn/server_tcp.conf
# OpenVPN TCP
port OVPNTCP
proto tcp
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh2048.pem
verify-client-cert none
username-as-common-name
key-direction 0
plugin /etc/openvpn/plugins/openvpn-plugin-auth-pam.so login
server 10.200.0.0 255.255.0.0
ifconfig-pool-persist ipp.txt
push "route-method exe"
push "route-delay 2"
keepalive 10 120
comp-lzo
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
log tcp.log
verb 2
ncp-disable
cipher none
auth none
myOpenVPNconf

cat <<'myOpenVPNconf2' > /etc/openvpn/server_udp.conf
# OpenVPN UDP
port OVPNUDP
proto udp
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh2048.pem
verify-client-cert none
username-as-common-name
key-direction 0
plugin /etc/openvpn/plugins/openvpn-plugin-auth-pam.so login
server 10.201.0.0 255.255.0.0
ifconfig-pool-persist ipp.txt
push "route-method exe"
push "route-delay 2"
keepalive 10 120
comp-lzo
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
log udp.log
verb 2
ncp-disable
cipher none
auth none
myOpenVPNconf2

 cat <<'EOF7'> /etc/openvpn/ca.crt
-----BEGIN CERTIFICATE-----
MIIFDDCCA/SgAwIBAgIJAIxbDcvh6vPEMA0GCSqGSIb3DQEBCwUAMIG0MQswCQYD
VQQGEwJQSDEPMA0GA1UECBMGVGFybGFjMRMwEQYDVQQHEwpDb25jZXBjaW9uMRMw
EQYDVQQKEwpKb2huRm9yZFRWMRMwEQYDVQQLEwpKb2huRm9yZFRWMRIwEAYDVQQD
EwlEZWJpYW5WUE4xHTAbBgNVBCkTFEpvaG4gRm9yZCBNYW5naWxpbWFuMSIwIAYJ
KoZIhvcNAQkBFhNhZG1pbkBqb2huZm9yZHR2Lm1lMB4XDTE5MTEyNTA4MDUzMFoX
DTI5MTEyMjA4MDUzMFowgbQxCzAJBgNVBAYTAlBIMQ8wDQYDVQQIEwZUYXJsYWMx
EzARBgNVBAcTCkNvbmNlcGNpb24xEzARBgNVBAoTCkpvaG5Gb3JkVFYxEzARBgNV
BAsTCkpvaG5Gb3JkVFYxEjAQBgNVBAMTCURlYmlhblZQTjEdMBsGA1UEKRMUSm9o
biBGb3JkIE1hbmdpbGltYW4xIjAgBgkqhkiG9w0BCQEWE2FkbWluQGpvaG5mb3Jk
dHYubWUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCf+WkN868YMiCl
d3z1Tq2OeRNb6ljiRGzEi1qrIvj/gXq6o0QD0SD+Nf3QWJrrJYFi1GECq72PNFhy
2jLFgZH0RRLOVZfG+jwZ9itxofweiwALvgMdz2e+mpQItMxKh1ZYkzNw+4zJ7zJV
u0Tq7YGPaMFPkLNU3V454rDYCdI8GG/wPDoW5FMc3FogI8fwylQvTWyE0yxHMxH6
FkISA5hOuSo6MO1FgAfDdNNwxa/MAbpHwJ+W6RBHv4lhE6bQePMCj/90pgt3NpxF
i++qwpSRfOR6OuuyDr1c++z6qhjLB7YzDLzj+HXCyfsPWPj+gJ0+3ckhW4gf/nhR
uB+BTd8fAgMBAAGjggEdMIIBGTAdBgNVHQ4EFgQULXGeDQBLXCPId0F3r/58FDCm
jC4wgekGA1UdIwSB4TCB3oAULXGeDQBLXCPId0F3r/58FDCmjC6hgbqkgbcwgbQx
CzAJBgNVBAYTAlBIMQ8wDQYDVQQIEwZUYXJsYWMxEzARBgNVBAcTCkNvbmNlcGNp
b24xEzARBgNVBAoTCkpvaG5Gb3JkVFYxEzARBgNVBAsTCkpvaG5Gb3JkVFYxEjAQ
BgNVBAMTCURlYmlhblZQTjEdMBsGA1UEKRMUSm9obiBGb3JkIE1hbmdpbGltYW4x
IjAgBgkqhkiG9w0BCQEWE2FkbWluQGpvaG5mb3JkdHYubWWCCQCMWw3L4erzxDAM
BgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQBZUpwZ+LQWAQI8VW3hdZVN
WV+P12yYQ1UzyagtB3MqBR4aZhjk42NFBrwPZwpvWUXB0GB4DhBuvbVPtqnt5p4V
sDtQ6vKYeDlE/KDGDc0oJDsgxo2wwIXy+y/14EDqidAVjtf1rk5MDAAEVvonHxkP
861kzoIOZ0+D7sJDo3aZ8uNy8UznrRSzLDT63o28DkL3iLASyt1GHWu05wYmgzsg
m+w+AWvN5rL65mzyn/Bipf0I9snVB4saCgfy7TCI/4slOcMCNc2e6oOwOLvFA+s8
dZMt2qg62PEOj/LblYGD+qLn0xLRwqK0UWSmWobz5LXoxyssZLK2KiMkS41PHkfh
-----END CERTIFICATE-----
EOF7
 cat <<'EOF9'> /etc/openvpn/server.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 1 (0x1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=PH, ST=Tarlac, L=Concepcion, O=PR Aiman, OU=PR Aiman, CN=DebianVPN/name=John Ford Mangiliman/emailAddress=admin@PR Aiman.me
        Validity
            Not Before: Nov 25 08:06:59 2019 GMT
            Not After : Nov 22 08:06:59 2029 GMT
        Subject: C=PH, ST=Tarlac, L=Concepcion, O=PR Aiman, OU=PR Aiman, CN=DebianVPN/name=John Ford Mangiliman/emailAddress=admin@PR Aiman.me
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:c6:6d:3d:64:58:08:e2:70:9b:a3:55:75:ec:5a:
                    6e:9d:bc:7c:45:f5:64:c5:f6:23:2e:b0:1f:28:2e:
                    cb:60:8d:71:73:3d:c4:e6:f7:e3:36:0b:ad:9d:87:
                    f5:4b:2f:85:5f:d8:c9:88:d9:86:4a:52:ce:2b:39:
                    c6:b9:83:e0:7e:ab:8e:1f:2f:11:cc:08:15:12:62:
                    dd:8d:94:b1:79:3c:52:d9:cb:0a:6a:db:64:8b:ff:
                    c7:41:5c:cc:f9:18:4f:74:1a:e7:c1:b4:b8:89:fd:
                    56:5f:5c:65:c4:21:a8:08:98:3d:8e:35:44:b3:6f:
                    93:b5:01:59:b4:35:23:99:00:79:fa:44:df:b3:4c:
                    76:bf:3c:e4:f7:39:3e:50:e0:fe:85:8c:a0:e2:63:
                    b1:ec:a3:32:cd:6b:9d:5a:0e:f6:66:92:ac:6f:15:
                    5e:bb:3a:48:d9:3d:63:94:ff:9c:fb:d2:fe:5a:11:
                    b5:1a:c1:6c:8a:9e:d3:29:8d:d6:ff:fc:9f:9f:a4:
                    ad:9d:a0:ca:2b:6f:63:47:7f:7b:3c:98:bf:14:18:
                    6c:36:38:7a:c3:5d:a9:5a:26:28:12:33:9d:17:1b:
                    6f:2f:5d:33:e7:b5:8f:57:3a:3a:29:57:6a:0e:9e:
                    84:7a:60:d9:9c:fb:c7:f3:f8:93:a7:cd:43:89:ec:
                    3f:d3
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints:
                CA:FALSE
            Netscape Cert Type:
                SSL Server
            Netscape Comment:
                Easy-RSA Generated Server Certificate
            X509v3 Subject Key Identifier:
                50:31:04:C4:7A:47:C1:DA:46:CC:77:38:DE:1C:63:10:40:C3:80:22
            X509v3 Authority Key Identifier:
                keyid:2D:71:9E:0D:00:4B:5C:23:C8:77:41:77:AF:FE:7C:14:30:A6:8C:2E
                DirName:/C=PH/ST=Tarlac/L=Concepcion/O=PR Aiman/OU=PR Aiman/CN=DebianVPN/name=John Ford Mangiliman/emailAddress=admin@PR Aiman.me
                serial:8C:5B:0D:CB:E1:EA:F3:C4
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Key Usage:
                Digital Signature, Key Encipherment
            X509v3 Subject Alternative Name:
                DNS:server
    Signature Algorithm: sha256WithRSAEncryption
         87:59:21:fd:7d:41:c8:87:8f:ff:13:85:e9:ae:31:da:43:bc:
         48:3b:32:41:ba:65:82:9e:76:25:cd:43:8b:fc:07:16:49:c3:
         8d:bd:ad:bf:0e:f6:d3:53:35:de:f2:c6:a6:62:c2:79:e1:49:
         a5:ba:55:cf:b9:e9:58:d8:e5:02:96:0a:2a:97:7d:82:85:0b:
         38:b5:dc:0d:6b:bd:51:a6:f7:3f:71:94:90:c9:ad:51:69:15:
         24:58:04:99:96:69:40:9d:a1:9c:1c:a3:34:be:b9:c2:86:61:
         ab:18:03:9b:27:b1:9f:1d:a3:5e:29:47:16:6f:7e:55:62:93:
         57:85:45:34:2c:cb:10:2c:da:f0:9a:ee:3d:b2:92:87:d4:7e:
         1b:c7:66:22:e9:4c:a2:95:d0:df:32:1a:87:ce:8a:27:08:f2:
         87:a9:e6:eb:16:37:71:35:37:4d:8c:0e:df:12:d3:e0:63:0a:
         53:7d:c8:02:c5:34:c5:23:68:c3:ba:33:5b:ad:92:bd:e2:d0:
         9d:bc:bd:bd:0d:64:50:0f:f4:bd:91:fc:10:e0:ec:01:e8:a1:
         50:ed:79:bf:12:49:bc:a4:93:17:d6:71:ed:9e:99:f3:42:6d:
         26:b3:2d:ac:32:62:98:71:d1:e4:83:6c:58:02:e6:49:b6:c9:
         73:76:eb:8b
-----BEGIN CERTIFICATE-----
MIIFfzCCBGegAwIBAgIBATANBgkqhkiG9w0BAQsFADCBtDELMAkGA1UEBhMCUEgx
DzANBgNVBAgTBlRhcmxhYzETMBEGA1UEBxMKQ29uY2VwY2lvbjETMBEGA1UEChMK
Sm9obkZvcmRUVjETMBEGA1UECxMKSm9obkZvcmRUVjESMBAGA1UEAxMJRGViaWFu
VlBOMR0wGwYDVQQpExRKb2huIEZvcmQgTWFuZ2lsaW1hbjEiMCAGCSqGSIb3DQEJ
ARYTYWRtaW5Aam9obmZvcmR0di5tZTAeFw0xOTExMjUwODA2NTlaFw0yOTExMjIw
ODA2NTlaMIG0MQswCQYDVQQGEwJQSDEPMA0GA1UECBMGVGFybGFjMRMwEQYDVQQH
EwpDb25jZXBjaW9uMRMwEQYDVQQKEwpKb2huRm9yZFRWMRMwEQYDVQQLEwpKb2hu
Rm9yZFRWMRIwEAYDVQQDEwlEZWJpYW5WUE4xHTAbBgNVBCkTFEpvaG4gRm9yZCBN
YW5naWxpbWFuMSIwIAYJKoZIhvcNAQkBFhNhZG1pbkBqb2huZm9yZHR2Lm1lMIIB
IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxm09ZFgI4nCbo1V17Fpunbx8
RfVkxfYjLrAfKC7LYI1xcz3E5vfjNgutnYf1Sy+FX9jJiNmGSlLOKznGuYPgfquO
Hy8RzAgVEmLdjZSxeTxS2csKattki//HQVzM+RhPdBrnwbS4if1WX1xlxCGoCJg9
jjVEs2+TtQFZtDUjmQB5+kTfs0x2vzzk9zk+UOD+hYyg4mOx7KMyzWudWg72ZpKs
bxVeuzpI2T1jlP+c+9L+WhG1GsFsip7TKY3W//yfn6StnaDKK29jR397PJi/FBhs
Njh6w12pWiYoEjOdFxtvL10z57WPVzo6KVdqDp6EemDZnPvH8/iTp81Diew/0wID
AQABo4IBmDCCAZQwCQYDVR0TBAIwADARBglghkgBhvhCAQEEBAMCBkAwNAYJYIZI
AYb4QgENBCcWJUVhc3ktUlNBIEdlbmVyYXRlZCBTZXJ2ZXIgQ2VydGlmaWNhdGUw
HQYDVR0OBBYEFFAxBMR6R8HaRsx3ON4cYxBAw4AiMIHpBgNVHSMEgeEwgd6AFC1x
ng0AS1wjyHdBd6/+fBQwpowuoYG6pIG3MIG0MQswCQYDVQQGEwJQSDEPMA0GA1UE
CBMGVGFybGFjMRMwEQYDVQQHEwpDb25jZXBjaW9uMRMwEQYDVQQKEwpKb2huRm9y
ZFRWMRMwEQYDVQQLEwpKb2huRm9yZFRWMRIwEAYDVQQDEwlEZWJpYW5WUE4xHTAb
BgNVBCkTFEpvaG4gRm9yZCBNYW5naWxpbWFuMSIwIAYJKoZIhvcNAQkBFhNhZG1p
bkBqb2huZm9yZHR2Lm1lggkAjFsNy+Hq88QwEwYDVR0lBAwwCgYIKwYBBQUHAwEw
CwYDVR0PBAQDAgWgMBEGA1UdEQQKMAiCBnNlcnZlcjANBgkqhkiG9w0BAQsFAAOC
AQEAh1kh/X1ByIeP/xOF6a4x2kO8SDsyQbplgp52Jc1Di/wHFknDjb2tvw7201M1
3vLGpmLCeeFJpbpVz7npWNjlApYKKpd9goULOLXcDWu9Uab3P3GUkMmtUWkVJFgE
mZZpQJ2hnByjNL65woZhqxgDmyexnx2jXilHFm9+VWKTV4VFNCzLECza8JruPbKS
h9R+G8dmIulMopXQ3zIah86KJwjyh6nm6xY3cTU3TYwO3xLT4GMKU33IAsU0xSNo
w7ozW62SveLQnby9vQ1kUA/0vZH8EODsAeihUO15vxJJvKSTF9Zx7Z6Z80JtJrMt
rDJimHHR5INsWALmSbbJc3briw==
-----END CERTIFICATE-----
EOF9
 cat <<'EOF10'> /etc/openvpn/server.key
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDGbT1kWAjicJuj
VXXsWm6dvHxF9WTF9iMusB8oLstgjXFzPcTm9+M2C62dh/VLL4Vf2MmI2YZKUs4r
Oca5g+B+q44fLxHMCBUSYt2NlLF5PFLZywpq22SL/8dBXMz5GE90GufBtLiJ/VZf
XGXEIagImD2ONUSzb5O1AVm0NSOZAHn6RN+zTHa/POT3OT5Q4P6FjKDiY7HsozLN
a51aDvZmkqxvFV67OkjZPWOU/5z70v5aEbUawWyKntMpjdb//J+fpK2doMorb2NH
f3s8mL8UGGw2OHrDXalaJigSM50XG28vXTPntY9XOjopV2oOnoR6YNmc+8fz+JOn
zUOJ7D/TAgMBAAECggEBALidRIRKwCFmIfhKeAfqb4aEqp8wXI0un7c9mA970i9I
CijtbHh0ZEqRfPvXViqY0R/HBGM195LJDhb7j2BlSYaxOO7cjVNmpaxQnc+va5vf
uzn1hgC7lQYIeSvgGrkbnDjrG3uHGDcSpLzeq7RamAs/Ee5wszW7dxLuabaXxkH/
owRXl6wvwD1WNGZsWJe8eP6GtBePm9+Ls5VLN0DPWyuJCFxhN/VpvvphECFt7EPF
qY+ysAFqfSYkCyH7OklnLIx1jQ04iLbZ4HI+S9QH+w1261fDgCXAmf1kgXkgLaM6
4wK+e93JRyqw87NZZIKN3ooq35n6wAUaS2erIYQFjrkCgYEA5c6qeNORIuq4F1jP
JS9aaXEjaAKIgw20qTyZfhQv6AhkJ7GASgWSdBIIfZQo1JG4EsXwqQ/0x9EwDOVu
glTYMT3tMi0zrzMklYS1G8iQElywAfTro/8sngfimvkQeRljoNdlrzO4+knUXmV8
DymPDH6UGlhj2FwCFN+obhT1f48CgYEA3QrzBK+YRu6iqeMuifwXlcbUS/A+dBPJ
qoYDzM6Zc0LYRTZSqhEHC8XkcQp/18LUxXFSrZXP2lcKmkqg4pgeAxALRLJW2pfz
yAm1Hah5JXlvTjX4HnMTFL4fvB0oGZXsAimPNa/wUZvTSPYJRziZdEwVubW3AAxE
THN3qxXoGX0CgYAWeSxwnnf+CygvmE7BmyzjTN4iiMTi1A9L0ZJNIxpAPbnVq+UY
2AynbzAHX9rSVuHCbDsJvXa5p7pkOHejJTrzLdQpaQQ56O119cFkUyvLr+bCejol
EopBdhHyB9NVlGcKzqWyCYPYbinnhVMphG3p0eMX5Hb3LKBDfE/TXBdZ/wKBgEwe
3iup8M3Ulk3c/4TjPJgGvctc85Tzz4oa1qosJ6oKxgGnwHXyoTOLtay8CeSaor1P
1kITCl5NhUg3FQqTihpR5x+ELubeV0R3G1kYUIf4Nr1/Vm/d/x8wjisw+0M8Xucr
urapXSAtgmho2i8drbLgFMc8bcXlc4vEY9yWEbTdAoGAMa6KTb0U9M47mpJb23zu
WiO8mFqSPYAnhHmXOiBOPlCoVpRbPquk3Xq32g9KU97jPNrH4X2HKgYpboMTWYOJ
kR3Y5UeFF1xurA/RXUEREcP1zg6Uei5aj7S4Sp7CVfIQCOpJ8S/I4CZdAcvwY+pI
ZTC1+KZJbFyPwFcrIylEeBc=
-----END PRIVATE KEY-----
EOF10
 cat <<'EOF13'> /etc/openvpn/dh2048.pem
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEAlrn8QcDrwXzqWCI7NMhPJVgEjdSxvyHw3EDVN8JrVfMegnvZA0VZ
St3hduXTzlT7ceUGIxTJpM8RE6d3f1mMPnZJ4hBxJzzjrwMgSCupJrQDjSAIWGLZ
elcmJS6WOAibpxzFIiPB6pRjoLaJF8b/J+YnO0bLUt1senWkg9ql8mU74VM1aG3A
jOPztpLqYIRwla11bqAl4UcFLBI+PXAcPJsAIfzZ3DMn7aOa3Or6UjSmVQ8jGY/8
1F0T67NgB8U7FrOVNimRlWfSJ//FiJkP0PScHVX2NQ0Cgwdo+wekjoFN5xbPxicc
LxNkdRPpCACgzdo1M77xVsurtfcxsz+RswIBAg==
-----END DH PARAMETERS-----
EOF13

 # Getting all dns inside resolv.conf then use as Default DNS for our openvpn server
 grep -v '#' /etc/resolv.conf | grep 'nameserver' | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | while read -r line; do
	echo "push \"dhcp-option DNS $line\"" >> /etc/openvpn/server_tcp.conf
done

 # Creating a New update message in server.conf
 cat <<'NUovpn' > /etc/openvpn/server.conf
 # New Update are now released, OpenVPN Server
 # are now running both TCP and UDP Protocol. (Both are only running on IPv4)
 # But our native server.conf are now removed and divided
 # Into two different configs base on their Protocols:
 #  * OpenVPN TCP (located at /etc/openvpn/server_tcp.conf
 #  * OpenVPN UDP (located at /etc/openvpn/server_udp.conf
 # 
 # Also other logging files like
 # status logs and server logs
 # are moved into new different file names:
 #  * OpenVPN TCP Server logs (/etc/openvpn/tcp.log)
 #  * OpenVPN UDP Server logs (/etc/openvpn/udp.log)
 #  * OpenVPN TCP Status logs (/etc/openvpn/tcp_stats.log)
 #  * OpenVPN UDP Status logs (/etc/openvpn/udp_stats.log)
 #
 # Server ports are configured base on env vars
 # executed/raised from this script (OpenVPN_TCP_Port/OpenVPN_UDP_Port)
 #
 # Enjoy the new update
 # Script Updated by jAvaNet
NUovpn

 # setting openvpn server port
 sed -i "s|OVPNTCP|$OpenVPN_TCP_Port|g" /etc/openvpn/server_tcp.conf
 sed -i "s|OVPNUDP|$OpenVPN_UDP_Port|g" /etc/openvpn/server_udp.conf
 
 # Getting some OpenVPN plugins for unix authentication
 cd
 wget https://myserver.aj-net.com/ovpnsc/deb9/files/plugins/plugin.tgz
 tar -xzvf /root/plugin.tgz -C /etc/openvpn/
 rm -f plugin.tgz
 
 # Some workaround for OpenVZ machines for "Startup error" openvpn service
 if [[ "$(hostnamectl | grep -i Virtualization | awk '{print $2}' | head -n1)" == 'openvz' ]]; then
 sed -i 's|LimitNPROC|#LimitNPROC|g' /lib/systemd/system/openvpn*
 systemctl daemon-reload
fi

 # Allow IPv4 Forwarding
 sed -i '/net.ipv4.ip_forward.*/d' /etc/sysctl.conf
 sed -i '/net.ipv4.ip_forward.*/d' /etc/sysctl.d/*.conf
 echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/20-openvpn.conf
 sysctl --system &> /dev/null

 # Iptables Rule for OpenVPN server
 cat <<'EOFipt' > /etc/openvpn/openvpn.bash
#!/bin/bash
PUBLIC_INET="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"
IPCIDR='10.200.0.0/16'
IPCIDR2='10.201.0.0/16'
iptables -I FORWARD -s $IPCIDR -j ACCEPT
iptables -I FORWARD -s $IPCIDR2 -j ACCEPT
iptables -t nat -A POSTROUTING -o $PUBLIC_INET -j MASQUERADE
iptables -t nat -A POSTROUTING -s $IPCIDR -o $PUBLIC_INET -j MASQUERADE
iptables -t nat -A POSTROUTING -s $IPCIDR2 -o $PUBLIC_INET -j MASQUERADE
EOFipt
 chmod +x /etc/openvpn/openvpn.bash
 bash /etc/openvpn/openvpn.bash

 # Enabling IPv4 Forwarding
 echo 1 > /proc/sys/net/ipv4/ip_forward
 
 # Starting OpenVPN server
 systemctl start openvpn@server_tcp
 systemctl enable openvpn@server_tcp
 systemctl start openvpn@server_udp
 systemctl enable openvpn@server_udp
}
 function InsProxy(){

 # Removing Duplicate privoxy config
 rm -rf /etc/privoxy/config*
 
 # Creating Privoxy server config using cat eof tricks
 cat <<'privoxy' > /etc/privoxy/config
# My Privoxy Server Config
user-manual /usr/share/doc/privoxy/user-manual
confdir /etc/privoxy
logdir /var/log/privoxy
filterfile default.filter
logfile logfile
listen-address 0.0.0.0:Privoxy_Port1
listen-address 0.0.0.0:Privoxy_Port2
toggle 1
enable-remote-toggle 0
enable-remote-http-toggle 0
enable-edit-actions 0
enforce-blocks 0
buffer-limit 4096
enable-proxy-authentication-forwarding 1
forwarded-connect-retries 1
accept-intercepted-requests 1
allow-cgi-request-crunching 1
split-large-forms 0
keep-alive-timeout 5
tolerate-pipelining 1
socket-timeout 300
permit-access 0.0.0.0/0 IP-ADDRESS
privoxy

 # Setting machine's IP Address inside of our privoxy config(security that only allows this machine to use this proxy server)
 sed -i "s|IP-ADDRESS|$IPADDR|g" /etc/privoxy/config
 
 # Setting privoxy ports
 sed -i "s|Privoxy_Port1|$Privoxy_Port1|g" /etc/privoxy/config
 sed -i "s|Privoxy_Port2|$Privoxy_Port2|g" /etc/privoxy/config

 # Removing Duplicate Squid config
 rm -rf /etc/squid/squid.con*
 
 # Creating Squid server config using cat eof tricks
 cat <<'mySquid' > /etc/squid/squid.conf
# My Squid Proxy Server Config
acl VPN dst IP-ADDRESS/32
http_access allow VPN
http_access deny all 
http_port Squid_Port1
http_port Squid_Port2
http_port Squid_Port3
### Allow Headers
request_header_access Allow allow all 
request_header_access Authorization allow all 
request_header_access WWW-Authenticate allow all 
request_header_access Proxy-Authorization allow all 
request_header_access Proxy-Authenticate allow all 
request_header_access Cache-Control allow all 
request_header_access Content-Encoding allow all 
request_header_access Content-Length allow all 
request_header_access Content-Type allow all 
request_header_access Date allow all 
request_header_access Expires allow all 
request_header_access Host allow all 
request_header_access If-Modified-Since allow all 
request_header_access Last-Modified allow all 
request_header_access Location allow all 
request_header_access Pragma allow all 
request_header_access Accept allow all 
request_header_access Accept-Charset allow all 
request_header_access Accept-Encoding allow all 
request_header_access Accept-Language allow all 
request_header_access Content-Language allow all 
request_header_access Mime-Version allow all 
request_header_access Retry-After allow all 
request_header_access Title allow all 
request_header_access Connection allow all 
request_header_access Proxy-Connection allow all 
request_header_access User-Agent allow all 
request_header_access Cookie allow all 
request_header_access All deny all
### HTTP Anonymizer Paranoid
reply_header_access Allow allow all 
reply_header_access Authorization allow all 
reply_header_access WWW-Authenticate allow all 
reply_header_access Proxy-Authorization allow all 
reply_header_access Proxy-Authenticate allow all 
reply_header_access Cache-Control allow all 
reply_header_access Content-Encoding allow all 
reply_header_access Content-Length allow all 
reply_header_access Content-Type allow all 
reply_header_access Date allow all 
reply_header_access Expires allow all 
reply_header_access Host allow all 
reply_header_access If-Modified-Since allow all 
reply_header_access Last-Modified allow all 
reply_header_access Location allow all 
reply_header_access Pragma allow all 
reply_header_access Accept allow all 
reply_header_access Accept-Charset allow all 
reply_header_access Accept-Encoding allow all 
reply_header_access Accept-Language allow all 
reply_header_access Content-Language allow all 
reply_header_access Mime-Version allow all 
reply_header_access Retry-After allow all 
reply_header_access Title allow all 
reply_header_access Connection allow all 
reply_header_access Proxy-Connection allow all 
reply_header_access User-Agent allow all 
reply_header_access Cookie allow all 
reply_header_access All deny all
### CoreDump
coredump_dir /var/spool/squid
dns_nameservers 8.8.8.8 8.8.4.4
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
visible_hostname PR Aiman
mySquid

 # Setting machine's IP Address inside of our Squid config(security that only allows this machine to use this proxy server)
 sed -i "s|IP-ADDRESS|$IPADDR|g" /etc/squid/squid.conf
 
 # Setting squid ports
 sed -i "s|Squid_Port1|$Squid_Port1|g" /etc/squid/squid.conf
 sed -i "s|Squid_Port2|$Squid_Port2|g" /etc/squid/squid.conf
 sed -i "s|Squid_Port3|$Squid_Port3|g" /etc/squid/squid.conf

 # Starting Proxy server
 echo -e "Restarting proxy server..."
 systemctl restart squid
}

function OvpnConfigs(){
 # Creating nginx config for our ovpn config downloads webserver
 cat <<'myNginxC' > /etc/nginx/conf.d/PR-Aiman-ovpn-config.conf
# My OpenVPN Config Download Directory
server {
 listen 0.0.0.0:myNginx;
 server_name localhost;
 root /var/www/openvpn;
 index index.html;
}
myNginxC

 # Setting our nginx config port for .ovpn download site
 sed -i "s|myNginx|$OvpnDownload_Port|g" /etc/nginx/conf.d/PR-Aiman-ovpn-config.conf

 # Removing Default nginx page(port 80)
 rm -rf /etc/nginx/sites-*

 # Creating our root directory for all of our .ovpn configs
 rm -rf /var/www/openvpn
 mkdir -p /var/www/openvpn

 # Now creating all of our OpenVPN Configs 

cat <<EOF16> /var/www/openvpn/javanet-tcp.ovpn
client
dev tun
proto tcp
setenv FRIENDLY_NAME "Gun-X"
remote $IPADDR $OpenVPN_TCP_Port
remote-cert-tls server
connect-retry infinite
resolv-retry infinite
nobind
persist-key
persist-tun
auth-user-pass
auth none
auth-nocache
cipher none
comp-lzo
redirect-gateway def1
setenv CLIENT_CERT 0
reneg-sec 0
verb 1
http-proxy $IPADDR $Squid_Port1
http-proxy-option VERSION 1.1
http-proxy-option AGENT Chrome/80.0.3987.87
http-proxy-option CUSTOM-HEADER Host www.opensignal.com
http-proxy-option CUSTOM-HEADER X-Forward-Host www.opensignal.com
http-proxy-option CUSTOM-HEADER X-Forwarded-For www.opensignal.com
http-proxy-option CUSTOM-HEADER Referrer www.opensignal.com
dhcp-option DNS 8.8.8.8
dhcp-option DNS 8.8.4.4
dhcp-option google.com
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
EOF16
cat <<EOF162> /var/www/openvpn/javanet-udp.ovpn
client
dev tun
proto udp
setenv FRIENDLY_NAME "Gun-X"
remote $IPADDR $OpenVPN_UDP_Port
http-proxy-option CUSTOM-HEADER Host www.opensignal.com
http-proxy-option CUSTOM-HEADER X-Forward-Host www.opensignal.com
http-proxy-option CUSTOM-HEADER X-Forwarded-For www.opensignal.com
http-proxy-option CUSTOM-HEADER Referrer www.opensignal.com
dhcp-option DNS 8.8.8.8
dhcp-option DNS 8.8.4.4
dhcp-option google.com
remote-cert-tls server
resolv-retry infinite
float
fast-io
nobind
persist-key
persist-remote-ip
persist-tun
auth-user-pass
auth none
auth-nocache
cipher none
comp-lzo
redirect-gateway def1
setenv CLIENT_CERT 0
reneg-sec 0
verb 1
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
EOF162
 # Creating OVPN download site index.html
cat <<'mySiteOvpn' > /var/www/openvpn/index.html
<!DOCTYPE html>
<html lang="en">
<!-- Simple OVPN Download site by PR-Aiman -->
<head><meta charset="utf-8" /><title>PR-Aiman OVPN Config Download</title><meta name="description" content="MyScriptName Server" /><meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" name="viewport" /><meta name="theme-color" content="#000000" /><link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.8.2/css/all.css"><link href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.3.1/css/bootstrap.min.css" rel="stylesheet"><link href="https://cdnjs.cloudflare.com/ajax/libs/mdbootstrap/4.8.3/css/mdb.min.css" rel="stylesheet"></head><body><div class="container justify-content-center" style="margin-top:9em;margin-bottom:5em;"><div class="col-md"><div class="view"><img src="https://openvpn.net/wp-content/uploads/openvpn.jpg" class="card-img-top"><div class="mask rgba-white-slight"></div></div><div class="card"><div class="card-body"><h5 class="card-title">Config List</h5><br /><ul class="list-group"><li class="list-group-item justify-content-between align-items-center" style="margin-bottom:1em;"><p>Revolution Become True<span class="badge light-blue darken-4">Android/iOS/PC/Modem</span><br /><small> Config OVPN Protocol UDP</small></p><a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/praiman-udp.ovpn" style="float:right;"><i class="fa fa-download"></i> Muat Turun</a></li><li class="list-group-item justify-content-between align-items-center" style="margin-bottom:1em;"><p>Revolution Become True<span class="badge light-blue darken-4">Android/iOS/PC/Modem</span><br /><small> Config OVPN Protocol TCP+PROXY</small></p><a class="btn btn-outline-success waves-effect btn-sm" href="http://IP-ADDRESS:NGINXPORT/praiman-tcp.ovpn" style="float:right;"><i class="fa fa-download"></i> Muat Turun</a></li></ul></div></div></div></div></body></html>
mySiteOvpn
 
 # Setting template's correct name,IP address and nginx Port
 sed -i "s|NGINXPORT|$OvpnDownload_Port|g" /var/www/openvpn/index.html
 sed -i "s|IP-ADDRESS|$IPADDR|g" /var/www/openvpn/index.html
 # Restarting nginx service
 systemctl restart nginx
 
 # Creating all .ovpn config archives
 cd /var/www/openvpn
 zip -qq -r configs.zip *.ovpn
 cd
}
function ip_address(){
  local IP="$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )"
  [ -z "${IP}" ] && IP="$( wget -qO- -t1 -T2 ipv4.icanhazip.com )"
  [ -z "${IP}" ] && IP="$( wget -qO- -t1 -T2 ipinfo.io/ip )"
  [ ! -z "${IP}" ] && echo "${IP}" || echo
} 
IPADDR="$(ip_address)"
function ConfStartup(){
 # Daily reboot time of our machine
 # For cron commands, visit https://crontab.guru
 echo -e "0 4\t* * *\troot\treboot" > /etc/cron.d/b_reboot_job
 # Creating directory for startup script
 rm -rf /etc/PR-Aiman
 mkdir -p /etc/PR-Aiman
 chmod -R 755 /etc/PR-Aiman
 
 # Creating startup script using cat eof tricks
 cat <<'EOFSH' > /etc/PR-Aiman/startup.sh
#!/bin/bash
# Setting server local time
ln -fs /usr/share/zoneinfo/MyVPS_Time /etc/localtime
# Prevent DOS-like UI when installing using APT (Disabling APT interactive dialog)
export DEBIAN_FRONTEND=noninteractive
# Allowing ALL TCP ports for our machine (Simple workaround for policy-based VPS)
iptables -A INPUT -s $(wget -4qO- http://ipinfo.io/ip) -p tcp -m multiport --dport 1:65535 -j ACCEPT
# Allowing OpenVPN to Forward traffic
/bin/bash /etc/openvpn/openvpn.bash
# Deleting Expired SSH Accounts
/usr/local/sbin/delete_expired &> /dev/null
exit 0
EOFSH
 chmod +x /etc/PR-Aiman/startup.sh
 
 # Setting server local time every time this machine reboots
 sed -i "s|MyVPS_Time|$MyVPS_Time|g" /etc/PR-Aiman/startup.sh
 # 
 rm -rf /etc/sysctl.d/99*
 # Setting our startup script to run every machine boots 
 cat <<'FordServ' > /etc/systemd/system/PR-Aiman.service
[Unit]
Description=PR-Aiman Startup Script
Before=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
ExecStart=/bin/bash /etc/PR-Aiman/startup.sh
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
FordServ
 chmod +x /etc/systemd/system/PR-Aiman.service
 systemctl daemon-reload
 systemctl start PR-Aiman
 systemctl enable PR-Aiman &> /dev/null
 systemctl enable fail2ban &> /dev/null
 systemctl start fail2ban &> /dev/null
 # Rebooting cron service
 systemctl restart cron
 systemctl enable cron
 
}
 #Create Admin
 useradd -m adgunx
 echo "adgunx:gunx" | chpasswd

clear
# IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
# if [[ "$IP" = "" ]]; then
IP=$(wget -4qO- "http://whatismyip.akamai.com/")
# fi

if [[ $(id -g) != "0" ]] ; then
    echo ""
    echo "Scrip : สั่งรูทคำสั่ง [ sudo -i ] ก่อนรันสคริปนี้  "
    echo ""
    exit
fi

if [[  ! -e /dev/net/tun ]] ; then
    echo "Scrip : TUN/TAP device is not available."
fi
cd
if [[ -e /etc/debian_version ]]; then
VERSION_ID=$(cat /etc/os-release | grep "VERSION_ID")
fi

cd

MYIP=$(wget -qO- ipv4.icanhazip.com);


clear
cd
echo

# Functions
ok() {
    echo -e '\e[32m'$1'\e[m';
}

die() {
    echo -e '\e[1;35m'$1'\e[m';
}
red() {
    echo -e '\e[1;31m'$1'\e[m';
}

des() {
    echo -e '\e[1;31m'$1'\e[m'; exit 1;
}


#
#<BODY text='ffffff'>

if [[ -d /etc/openvpn ]]; then
clear
cd
echo
    ok " Script : ได้ติดตั้ง openvpn ใว้แล้วก่อนหน้านี้  ."
    ok " Script : ต้องการติดตั้งทับหรือไม่ ฟังชั่นบางบางอาจไม่ทำงาน "
    read -p " Script y/n : " -e -i y enter
 if [[ $enter = y || $enter = Y ]]; then
 clear
cd
echo
else
clear
cd
echo
exit
fi
else
clear
cd
echo
fi

clear

# ads
echo ""
echo ""
echo "    =============== OS-32 & 64-bit =================    "
echo "    #                                              #    "
echo "    #       AUTOSCRIPT CREATED BY PIRAKIT          #    "
echo "    #      -----------About Us------------         #    "
echo "    #      OS  DEBIAN 7-8-9  OS  UBUNTU 14-16      #    "
echo "    #    Truemoney Wallet : 096-746-2978           #    "
echo "    #               { VPN / SSH }                  #    "
echo "    #                  NAMNUEA                     #    "
echo "    #         BY : Pirakit Khawpleum               #    "
echo "    #    FB : https://m.me/pirakrit.khawplum       #    "
echo "    #                                              #    "
echo "    =============== OS-32 & 64-bit =================    "
echo ""
echo "    ~¤~ ๏[-ิ_•ิ]๏ ~¤~ Admin MyGatherBK ~¤~ ๏[-ิ_•ิ]๏ ~¤~ "
echo ""
echo " ไอพีเซิฟ:$IP "
echo ""
echo ""
# Install openvpn
cd
echo "
----------------------------------------------
[√] ระบบสคริป  : Pirakit Khawpleum 
[√] กรุณารอสักครู่ .....
[√] Loading .....
----------------------------------------------
 "
ok "➡ apt-get update"
apt-get update -q > /dev/null 2>&1
ok "➡ apt-get install openvpn curl openssl"
apt-get install -qy openvpn curl > /dev/null 2>&1

# IP Address
SERVER_IP=$(wget -qO- ipv4.icanhazip.com);
if [[ "$SERVER_IP" = "" ]]; then
    SERVER_IP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0' | grep -v '192.168'`;
fi


# setting port ssh
cd
sed -i 's/Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 443' /etc/ssh/sshd_config
ok "➡ service ssh restart"
service ssh restart > /dev/null 2>&1

# install dropbear
ok "➡ apt-get install dropbear"
apt-get install -qy dropbear > /dev/null 2>&1
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=3128/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 143"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
ok "➡ service dropbear restart"
service dropbear restart > /dev/null 2>&1



# install stunnel
ok "➡ apt-get install ssl"
apt-get install -qy stunnel4 > /dev/null 2>&1
cat > /etc/stunnel/stunnel.conf <<-END
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1


[stunnel]
accept = 444
connect = 127.0.0.1:22

END

#membuat sertifikat
cat /etc/openvpn/client-key.pem /etc/openvpn/client-cert.pem > /etc/stunnel/stunnel.pem

#konfigurasi stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
ok "➡ service ssl restart"
service stunnel4 restart > /dev/null 2>&1

# install vnstat gui
ok "➡ apt-get install vnstat"
apt-get install -qy php5-fpm > /dev/null 2>&1
chown -R vnstat:vnstat /var/lib/vnstat
cd /home/vps/public_html
wget -q http://www.sqweek.com/sqweek/files/vnstat_php_frontend-1.5.1.tar.gz
tar xf vnstat_php_frontend-1.5.1.tar.gz
rm vnstat_php_frontend-1.5.1.tar.gz
mv vnstat_php_frontend-1.5.1 bandwidth
cd bandwidth
sed -i "s/\$iface_list = array('eth0', 'sixxs');/\$iface_list = array('eth0');/g" config.php
sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
sed -i 's/Internal/Internet/g' config.php
sed -i '/SixXS IPv6/d' config.php
sed -i "s/\$locale = 'en_US.UTF-8';/\$locale = 'en_US.UTF+8';/g" config.php

if [ -e '/var/lib/vnstat/eth0' ]; then
	vnstat -u -i eth0
else
sed -i "s/eth0/ens3/g" /home/vps/public_html/bandwidth/config.php
vnstat -u -i ens3
fi

ok "➡ service vnstat restart"
service vnstat restart -q > /dev/null 2>&1

# Iptables
ok "➡ apt-get install iptables"
apt-get install -qy iptables > /dev/null 2>&1
if [ -e '/var/lib/vnstat/eth0' ]; then
iptables -t nat -I POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
else
iptables -t nat -I POSTROUTING -s 10.8.0.0/24 -o ens3 -j MASQUERADE
fi
iptables -I FORWARD -s 10.8.0.0/24 -j ACCEPT
iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
 iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to-source $SERVER_IP

iptables-save > /etc/iptables.conf

cat > /etc/network/if-up.d/iptables <<EOF
#!/bin/sh
iptables-restore < /etc/iptables.conf
EOF

chmod +x /etc/network/if-up.d/iptables

# Enable net.ipv4.ip_forward
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf
echo 1 > /proc/sys/net/ipv4/ip_forward

# setting time
ln -fs /usr/share/zoneinfo/Asia/Bangkok /etc/localtime
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service ssh restart

 
# download script
cd /usr/bin
wget -q -O z "https://raw.githubusercontent.com/teamvpn/script_thai/master/menu"
wget -q -O speedtest "https://raw.githubusercontent.com/teamvpn/script_thai/master/speedtest"
wget -q -O b-user "https://raw.githubusercontent.com/teamvpn/script_thai/master/b-user"


echo "30 3 * * * root /sbin/reboot" > /etc/cron.d/reboot
chmod +x speedtest
chmod +x z
chmod +x b-user
service cron restart -q > /dev/null 2>&1


# XML Parser
ok "➡ apt-get install XML Parser"
cd
apt-get -y --force-yes -f install libxml-parser-perl


clear
clear
# ads
echo ""
echo ""
echo "    =============== OS-32 & 64-bit =================    "
echo "    #                                              #    "
echo "    #       AUTOSCRIPT CREATED BY PIRAKIT          #    "
echo "    #      -----------About Us------------         #    "
echo "    #      OS  DEBIAN 7-8-9  OS  UBUNTU 14-16      #    "
echo "    #    Truemoney Wallet : 096-746-2978           #    "
echo "    #               { VPN / SSH }                  #    "
echo "    #                  NAMNUEA                     #    "
echo "    #         BY : Pirakit Khawpleum               #    "
echo "    #    FB : https://m.me/pirakrit.khawplum       #    "
echo "    #                                              #    "
echo "    =============== OS-32 & 64-bit =================    "
echo ""
echo "    ~¤~ ๏[-ิ_•ิ]๏ ~¤~ Admin MyGatherBK ~¤~ ๏[-ิ_•ิ]๏ ~¤~ "
echo ""
echo " ไอพีเซิฟ:$IP "
echo ""
echo ""
----------------------------------------------
[√] INSTALL SUCCESS ^^
[√] การติดตั้งเสร็จสมบรูณ์ .....
[√] OK .....
----------------------------------------------"
echo ""
echo ""
echo -e "\e[32m    ##############################################################    "
echo -e "\e[32m    #                                                            #    "
echo -e "\e[32m    #      >>>>> [ ระบบสคริป :PRATYASART THEEJANMART ] <<<<<       #    "
echo -e "\e[32m    #                                                            #    "
echo -e "\e[32m    #             SYSTEM MANAGER VPN SSH                         #    "
echo -e "\e[32m    #                                                            #    "
echo -e "\e[32m    #    Dropbear       :   22, 443                              #    "
echo -e "\e[32m    #    SSL            :   444                                  #    "
echo -e "\e[32m    #    Squid3         :   3128, 8080                           #    "
echo -e "\e[32m    #    OpenVPN        :   TCP 1194 [Edit] TCP 443              #    "
echo -e "\e[32m    #    Nginx          :   85                                   #    "
echo -e "\e[32m    #                                                            #    "
echo -e "\e[32m    #             LIMIT SETTINGS VPN SSH                         #    "
echo -e "\e[32m    #                                                            #    "
echo -e "\e[32m    #    Timezone       :   Asia/Bangkok                         #    "
echo -e "\e[32m    #    IPV6           :   [OFF]                                #    "
echo -e "\e[32m    #    Cron Scheduler :   [ON]                                 #    "
echo -e "\e[32m    #    Fail2Ban       :   [ON]                                 #    "
echo -e "\e[32m    #    DDOS Deflate   :   [ON]                                 #    "
echo -e "\e[32m    #    LibXML Parser  :   [ON]                                 #    "
echo -e "\e[32m    #                                                            #    "
echo -e "\e[32m    #    ติดตั้งสำเร็จ... กรุณาพิมพ์คำสั่ง    z เพื่อไปยังขั้นตอนถัดไป         #    "
echo -e "\e[32m    #                                                            #    "
echo -e "\e[32m    ##############################################################    "
echo -e "\e[0m                                                                       "
read -n1 -r -p "                Press Enter To Show Commands                         "
z

cd
rm -f install
rm -f /root/install_openvpn
