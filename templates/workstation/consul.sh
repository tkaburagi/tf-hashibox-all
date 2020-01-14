#!/usr/bin/env bash
set -e

echo "==> Consul (client)"

echo "--> Create `consul` user"
sudo useradd consul

echo "--> Fetching"
install_from_url "consul" "${consul_url}"

echo "--> Writing configuration"
sudo mkdir -p /mnt/consul
sudo mkdir -p /etc/consul.d
sudo tee /etc/consul.d/config.json > /dev/null <<EOF
{
  "advertise_addr": "$(private_ip)",
  "advertise_addr_wan": "$(public_ip)",
  "bind_addr": "$(private_ip)",
  "data_dir": "/mnt/consul",
  "disable_update_check": true,
  "encrypt": "${consul_gossip_key}",
  "enable_script_checks": false,
  "enable_agent_tls_for_checks": true,
  "leave_on_terminate": true,
  "node_name": "${node_name}",
  "raft_protocol": 3,
  "ui": true,
  "retry_join": ["provider=aws tag_key=${consul_join_tag_key} tag_value=${consul_join_tag_value}"],

  "addresses": {
    "http": "127.0.0.1"
  },
  "ports": {
    "http": 8500
  },
  "connect": {
    "enabled": true
  }
}
EOF

echo "--> Writing profile"
sudo tee /etc/profile.d/consul.sh > /dev/null <<"EOF"
alias conslu="consul"
alias ocnsul="consul"
EOF
source /etc/profile.d/consul.sh

echo "--> Creating dashboard service"
sudo tee /etc/consul.d/dashboard.json > /dev/null <<"EOF"
{
  "service": {
    "name": "dashboard",
    "port": 9002,
    "connect": {
      "proxy": {}
    },
    "check": {
      "id": "dashboard-check",
      "http": "http://localhost:9002/health",
      "method": "GET",
      "interval": "1s",
      "timeout": "1s"
    }
  }
}
EOF
sudo tee /etc/consul.d/counting.json > /dev/null <<"EOF"
{
  "service": {
    "name": "counting",
    "port": 9003,
    "connect": {
      "proxy": {}
    },
    "check": {
      "id": "counting-check",
      "http": "http://localhost:9003/health",
      "method": "GET",
      "interval": "1s",
      "timeout": "1s"
    }
  }
}
EOF

echo "--> Making consul.d world-writable..."
sudo chmod --recursive 0777 /etc/consul.d/
sudo chmod --recursive 0777 /mnt/consul

echo "--> Generating systemd configuration"
sudo tee /etc/systemd/system/consul.service > /dev/null <<"EOF"
[Unit]
Description=Consul
Documentation=https://www.consul.io/docs/
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
ExecStart=/usr/local/bin/consul agent -config-dir="/etc/consul.d"
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
User=consul

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable consul
sudo systemctl start consul

echo "--> Installing dnsmasq"
ssh-apt install dnsmasq
sudo tee /etc/dnsmasq.d/10-consul > /dev/null <<"EOF"
server=/consul/127.0.0.1#8600
no-poll
server=8.8.8.8
server=8.8.4.4
cache-size=0
EOF
sudo systemctl enable dnsmasq
sudo systemctl restart dnsmasq

echo "==> Consul is done!"
