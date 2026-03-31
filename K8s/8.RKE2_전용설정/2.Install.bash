# 1. RKE2 마스터 노드 설치 스크립트 (install-rke2-master.sh)

#!/bin/bash

# 1. 환경 변수 설정 (본인의 환경에 맞게 수정하세요)
VIP="192.168.0.100" # Keepalived로 생성한 가상 IP
NODE_IP=$(hostname -I | awk '{print $1}') # 현재 서버의 실제 IP
TOKEN="hp-k8s-cluster-2024"  # 노드 간 연결을 위한 보안 토큰 (임의 지정)

echo ">>> [1/5] OS 커널 및 방화벽 사전 설정 시작..."
# 스왑 비활성화
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 방화벽 설정 (학습 단계에서는 잠시 끄거나 특정 대역 허용)
sudo ufw disable 

echo ">>> [2/5] RKE2 설정 디렉토리 생성 및 config.yaml 작성..."
sudo mkdir -p /etc/rancher/rke2

cat <<EOF | sudo tee /etc/rancher/rke2/config.yaml
# 고가용성 API 서버 접속 정보
tls-san:
  - "${VIP}"
  - "${NODE_IP}"
write-kubeconfig-mode: "0644" # 쿠베컨피그 권한 설정 (일반 사용자용)

# 노드 및 네트워크 설정
token: "${TOKEN}"
node-ip: "${NODE_IP}"
cni:
  - calico

# 기본 컴포넌트 커스텀 (HAProxy Ingress 사용을 위해 내장 Nginx 비활성)
disable:
  - rke2-ingress-nginx  # 나중에 HAProxy Ingress 설치 예정

# 네트워크 플러그인 (실운영 권장 Calico)
cni:
  - calico
EOF

echo ">>> [3/5] RKE2 바이너리 다운로드 및 설치..."
curl -sfL https://rke2.io | sudo sh

echo ">>> [4/5] RKE2 서비스 활성화 및 시작 (시간이 다소 소요됩니다)..."
sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service

echo ">>> [5/5] Kubectl 환경 변수 및 별칭 설정..."
mkdir -p $HOME/.kube
sudo cp /etc/rancher/rke2/rke2.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo 'export PATH=$PATH:/var/lib/rancher/rke2/bin' >> ~/.bashrc
source ~/.bashrc

echo "======================================================"
echo "RKE2 Master Node 설치 완료!"
echo "노드 상태 확인: kubectl get nodes"
echo "======================================================"

# 2. 실행 방법
## 위 내용을 파일로 저장합니다: vi install-rke2-master.sh
## 실행 권한을 부여합니다: chmod +x install-rke2-master.sh
## 스크립트를 실행합니다: ./install-rke2-master.sh

# 3. 설치 후 필수 체크포인트
## 상태 확인: kubectl get nodes 명령어를 쳤을 때 본인의 호스트명이 Ready로 바뀌는지 확인하세요 (약 1~2분 소요).
## 로그 확인: 설치 중 문제가 생기면 sudo journalctl -u rke2-server -f 명령어로 실시간 로그를 볼 수 있습니다.
## VIP 작동: 이 스크립트 실행 전, 반드시 Keepalived와 HAProxy가 먼저 설정되어 VIP(192.168.0.100)가 살아있어야 클러스터 통신이 정상적으로 이루어집니다.
