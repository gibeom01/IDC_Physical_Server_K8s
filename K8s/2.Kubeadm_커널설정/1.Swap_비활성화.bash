###### K8s의 kubelet은 노드의 자원을 정밀하게 관리하기 위해 스왑이 꺼져 있는 것을 전제로 동작합니다.

# 즉시 비활성화
sudo swapoff -a

# 재부팅 시에도 적용되도록 /etc/fstab에서 swap 설정 주석 처리
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
