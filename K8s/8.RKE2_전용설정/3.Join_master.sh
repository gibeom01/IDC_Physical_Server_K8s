#!/bin/bash

# 1. 환경 변수 설정 (첫 번째 마스터와 동일한 VIP 및 TOKEN 사용)
VIP="192.168.0.100"             # 첫 번째 마스터가 바라보는 VIP
NODE_IP=$(hostname -I | awk '{print $1}') # 현재(두 번째) 서버의 실제 IP
TOKEN="hp-k8s-cluster-2024"     # 첫 번째 마스터 설치 시 설정한 TOKEN

echo ">>> [1/4] 시스템 사전 설정 (Swap Off)..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# RKE2 설정 디렉토리 생성
sudo mkdir -p /etc/rancher/rke2

echo ">>> [2/4] RKE2 조인용 config.yaml 생성..."
cat <<EOF | sudo tee /etc/rancher/rke2/config.yaml
# 클러스터 리더(VIP) 주소 지정 (조인 핵심 설정)
server: https://${VIP}:9345

# 외부 접속 및 고가용성을 위한 SAN 설정
tls-san:
  - "${VIP}"
  - "${NODE_IP}"

# 노드 식별 및 보안 토큰 (리더와 일치해야 함)
token: "${TOKEN}"
node-ip: "${NODE_IP}"

# 쿠베컨피그 권한 설정
write-kubeconfig-mode: "0644"

# 리더와 동일한 컴포넌트 구성
disable:
  - rke2-ingress-nginx
cni:
  - calico
EOF

echo ">>> [3/4] RKE2 서버 설치 및 조인 시작..."
# RKE2 바이너리 다운로드 및 설치
curl -sfL https://rke2.io | sudo sh

# 서비스 활성화 및 시작 (리더와 동기화하느라 시간이 소요됨)
sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service

echo ">>> [4/4] Kubectl 환경 변수 설정..."
echo 'export PATH=$PATH:/var/lib/rancher/rke2/bin' >> ~/.bashrc
mkdir -p $HOME/.kube
sudo cp /etc/rancher/rke2/rke2.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

source ~/.bashrc

echo "===================================================="
echo " RKE2 Secondary Master Node 조인 완료!"
echo " 상태 확인: kubectl get nodes"
echo "===================================================="
