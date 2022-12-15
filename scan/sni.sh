curl --insecure \
     --include \
     --no-buffer \
     --header "Connection: Upgrade" \
     --header "Upgrade: websocket" \
     --header "Host: sanggoro5.nextvpn.cc" \
     --header "Origin: https://g.vo" \
     --header "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" \
     --header "Sec-WebSocket-Version: 13" \
     --key ~/.ssh/id_rsa --pass private_key_password \
https://$1 --http1.1 -v
