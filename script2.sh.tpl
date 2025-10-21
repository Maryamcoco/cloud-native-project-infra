#!/bin/bash
set -e

# Update system
sudo apt-get update -y
sudo apt-get install -y wget tar

# Install Prometheus
cd /opt
sudo wget https://github.com/prometheus/prometheus/releases/download/v2.53.0/prometheus-2.53.0.linux-amd64.tar.gz
sudo tar -xvzf prometheus-2.53.0.linux-amd64.tar.gz
sudo mv prometheus-2.53.0.linux-amd64 prometheus
cd prometheus

# Create Prometheus config with injected IPs
cat <<EOF | sudo tee /opt/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "node_exporter"
    static_configs:
      - targets: ["${jenkins_private_ip}:9100"]

  - job_name: "jenkins"
    metrics_path: /metrics
    static_configs:
      - targets: ["${jenkins_private_ip}:8081"]

  - job_name: "blackbox_jenkins"
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets: ["http://${jenkins_public_ip}:8081"]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: localhost:9115

  - job_name: "blackbox_app"
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets: ["http://${jenkins_public_ip}:8080"]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: localhost:9115
EOF

# Install Blackbox Exporter
cd /opt
sudo wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.25.0/blackbox_exporter-0.25.0.linux-amd64.tar.gz
sudo tar -xvzf blackbox_exporter-0.25.0.linux-amd64.tar.gz
sudo mv blackbox_exporter-0.25.0.linux-amd64 blackbox_exporter

# Install Grafana
sudo apt-get install -y apt-transport-https software-properties-common
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update -y
sudo apt-get install -y grafana

# Enable & start services
nohup /opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml > /opt/prometheus/prometheus.log 2>&1 &
nohup /opt/blackbox_exporter/blackbox_exporter > /opt/blackbox_exporter/blackbox.log 2>&1 &
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
