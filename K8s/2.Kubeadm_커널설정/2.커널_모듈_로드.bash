###### 컨테이너 네트워크가 호스트의 네트워크 브릿지를 통과하고, 방화벽 규칙을 적용받을 수 있도록 관련 모듈을 로드합니다.

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# 모듈 즉시 로드
sudo modprobe overlay
sudo modprobe br_netfilter
