# echo -e $(cat raw.http) | curl -k --resolve www.skillacademy.com:443:104.18.24.139 --connect-to www.skillacademy.com:443:104.18.24.139:443 --haproxy-protocol --proxy-insecure --tlsv1.2 --tcp-fastopen --tcp-nodelay --false-start --proxy www.skillacademy.com:443 telnet://www.skillacademy.com:443


#  --resolve www.skillacademy.com:443:104.18.24.139 --connect-to www.skillacademy.com:443:104.18.24.139:443
# curl -x https://177.12.238.1:3128 --resolve www.skillacademy.com:443:104.18.24.139  https://www.skillacademy.com:443

# export https_proxy=https://20.206.106.192:8123/;curl --resolve www.skillacademy.com:443:104.18.24.139  https://www.skillacademy.com:443 -vvv

# openssl s_client -connect 20.206.106.192:8123 -servername github.com
# openssl s_client -connect 177.12.238.1:3128 -servername github.com



# export http_proxy=https://104.129.204.32:10605;curl -k https://ifconfig.me -vvv


# export http_proxy=https://104.129.204.32:10605;curl -k https://ifconfig.me -vvv
# openssl x509 -in sanggoro5.nextvpn.cc -text

# echo | openssl s_client -connect mysite.com:443 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > cert.pem


# curl -k https://ifconfig.me -vvv -x https://104.129.204.32:10605 --haproxy-protocol -I --insecure --proto-default https --proxy-cacert firefox.pem


# echo quit | openssl s_client -showcerts -servername google.com -connect sanggoro5.nextvpn.cc:443 > cacert.pem



# curl --proxy-cacert c9.dev.pem https://ifconfig.me


# curl -k https://ifconfig.me -vvv -x http://20.206.106.192:8123 --proxy-insecure



# echo -e $(cat raw.http) | curl -k --resolve www.skillacademy.com:443:104.18.25.139 --connect-to www.skillacademy.com:443:104.18.25.139:443 --proxy-insecure --proxy http://www.skillacademy.com:443 telnet://www.skillacademy.com:443

# https://104.18.25.139:443

# echo -e $(cat raw.http) | curl -k --resolve www.skillacademy.com:443:104.18.24.139 --connect-to www.skillacademy.com:443:104.18.24.139:443 --proxy-insecure --tlsv1.0 --proxy www.skillacademy.com:443 --http1.1 telnet://www.skillacademy.com:443
echo -e $(cat raw.http)|curl -k --resolve www.skillacademy.com:443:104.18.24.139 --connect-to www.skillacademy.com:443:104.18.24.139:443 telnet://www.skillacademy.com:80
    