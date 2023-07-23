export DEFAULT_SNI_HOST="melbi2.nextvpn.cc" ## sni_curl,sni_openssl
export DEFAULT_SNI_HOST_IP="103.172.116.151" ## sni_curl,sni_openssl
export DEFAULT_USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.102 Safari/537.36 OPR/90.0.4480.100" ## http_status,https_status,proxy
# export BLACKLIST_REDIRECT="https://myim3.ioh.co.id/"
# export BLACKLIST_REDIRECT="http://kuotahabis.tri.co.id/frontpage/" ## http_status,https_status,proxy
# export BLACKLIST_REDIRECT="http://123.xl.co.id/min_balance8" ## http_status,https_status,proxy

export BLACKLIST_REDIRECT="https://myim3.ioh.co.id/,http://kuotahabis.tri.co.id/frontpage/,http://123.xl.co.id/min_balance8"
# echo ${BLACKLIST_URL[1]}
export DEFAULT_CONNECT_TIMEOUT="5" ## sni_curl
export DEFAULT_MAX_TIMEOUT="5" ## sni_curl
export DEFAULT_TIMEOUT="10" ## sni_openssl
export DEFAULT_THREAD="100" ## bulk
export terminal_width=$(( $(stty size | awk '{print $2}') - 30 ))
