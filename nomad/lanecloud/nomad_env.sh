HASHI_REMOTE_HOST=hashiserver.example.com
export NOMAD_ADDR=http://${HASHI_REMOTE_HOST}:4646
export CONSUL_HTTP_ADDRESS=${HASHI_REMOTE_HOST}:8500