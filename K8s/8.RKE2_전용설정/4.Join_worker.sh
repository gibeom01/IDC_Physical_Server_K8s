#!/bin/bash

# 1. 환경 변수 설정 (마스터 노드와 동일한 VIP 및 TOKEN 사용)
VIP="192.168.0.100"             # 마스터 노드들이 묶여있는 VIP
NODE_IP=$(hostname -I | awk '{print $1}') # 현재 워커 서버의 실제 IP
TOKEN="hp-k8s-cluster-2024"     # 마스터 설치 시 설정한 TOKEN

echo ">>> [1/4] 시스템 사전 설정 (Swap Off)..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# RKE2 설정 디렉토리 생성
sudo mkdir -p /etc/rancher/rke2

echo ">>> [2/4] RKE2 워커용 config.yaml 생성..."
cat <<EOF | sudo tee /etc/rancher/rke2/config.yaml
# 마스터 서버(VIP) 주소 지정 (에이전트 조인 핵심)
server: https://${VIP}:9345

# 보안 토큰 (마스터와 일치해야 함)
token: "${TOKEN}"

# 현재 노드 IP 명시
node-ip: "${NODE_IP}"
EOF

echo ">>> [3/4] RKE2 에이전트(Agent) 설치 및 조인 시작..."
# RKE2 바이너리 다운로드 (에이전트 모드로 설치)
curl -sfL https://rke2.io | INSTALL_RKE2_TYPE="agent" sudo sh

# 서비스 활성화 및 시작
sudo systemctl enable rke2-agent.service
sudo systemctl start rke2-agent.service

echo ">>> [4/4] 설치 확인 가이드..."
echo "===================================================="
echo " RKE2 Worker Node 조인 명령 완료!"
echo " 마스터 노드에서 'kubectl get nodes'를 입력하여"
echo " 현재 노드가 'Ready' 상태로 올라오는지 확인하세요."
echo "===================================================="
