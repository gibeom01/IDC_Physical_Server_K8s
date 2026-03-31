# 1. 확인 (Verification)
###### 설정이 올바르게 되었는지 아래 명령어로 확인하세요.
## 모듈 로드 확인: lsmod | grep -e overlay -e br_netfilter
## sysctl 적용 확인: sysctl net.bridge.bridge-nf-call-iptables net.ipv4.ip_forward (둘 다 1이 나와야 함)

# 💡 팁: ESXi 환경에서의 컨테이너 런타임
###### 커널 설정 후에는 컨테이너를 실행할 엔진인 containerd를 설치해야 합니다. containerd 설치 후에는 아래 명령어로 설정 파일을 생성해야 K8s와 정상 통신이 가능합니다.

# containerd 기본 설정 생성
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# SystemdCgroup 설정을 true로 변경 (K8s 권장 사항)
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# 서비스 재시작
sudo systemctl restart containerd
