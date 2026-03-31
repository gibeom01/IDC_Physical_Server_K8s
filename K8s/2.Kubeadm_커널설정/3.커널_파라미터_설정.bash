###### 네트워크 트래픽이 브릿지 계층에서 iptables 규칙을 따르도록 설정하고, IP 포워딩(IPv4 Forwarding)을 활성화합니다.

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# 설정 즉시 적용
sudo sysctl --system
