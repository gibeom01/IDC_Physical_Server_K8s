###### 반드시 모든 노드(마스터 및 워커)에서 수행해야 합니다. Kubernetes 공식 APT 저장소 설정을 포함한 설치 절차입니다. (Ubuntu 22.04 기준)

# 1. 기본 패키지 업데이트 및 필요한 도구 설치
###### 저장소 통신을 위한 인증서와 다운로드 도구를 먼저 설치합니다.

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg


# 2. Kubernetes 공개 서명 키(GPG) 다운로드
###### 패키지의 무결성을 확인하기 위한 키를 등록합니다.

# 디렉토리가 없다면 생성
sudo mkdir -p -m 755 /etc/apt/keyrings

# 공식 GPG 키 다운로드 및 저장
curl -fsSL https://k8s.io | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
###### (참고: v1.29 부분은 최신 안정 버전에 맞춰 변경 가능합니다.)

# 3. Kubernetes APT 저장소 추가
###### 시스템에 K8s 패키지 경로를 알려줍니다.

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://k8s.io /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 4. K8s 도구 설치 (Kubeadm, Kubelet, Kubectl)
###### 이제 실제 도구들을 설치합니다.

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# 자동 업데이트 방지 (버전 관리를 위해 고정)
sudo apt-mark hold kubelet kubeadm kubectl

# 5. 서비스 활성화
###### 설치 후 kubelet이 시스템 시작 시 자동으로 실행되도록 설정합니다.

sudo systemctl enable --now kubelet

# 🚀 다음 단계: 클러스터 초기화 (Init)
###### 모든 설정이 완료되었다면, Master 1번 노드에서 아까 준비한 VIP를 사용해 클러스터를 시작하면 됩니다.

# 예시 명령 (VIP가 192.168.0.100일 경우)
sudo kubeadm init \
  --control-plane-endpoint "192.168.0.100:6443" \
  --upload-certs \
  --pod-network-cidr=10.244.0.0/16
