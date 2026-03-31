###### 마스터 노드에서 kubeadm init 명령이 성공하면, 화면에 두 종류의 Join 명령어가 출력됩니다. 하나는 일반 워커 노드용이고, 다른 하나는 추가 마스터 노드(Control Plane)용입니다.

# 1. 추가 마스터 노드 조인 (Join Control Plane)
###### 두 번째 마스터 노드(Master 2)에서 실행합니다. 이때 --control-plane과 --certificate-key 옵션이 포함된 명령어를 사용해야 합니다.

# 예시 (실제 토큰과 키는 본인의 실행 결과에서 복사하세요)
sudo kubeadm join 192.168.0.100:6443 --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash> \
    --control-plane --certificate-key <key>

###### 성공 확인: 조인이 완료되면 kubectl get nodes 명령어로 노드 상태가 NotReady인 것을 확인합니다. (CNI가 없기 때문입니다.)

# 2. 네트워크(CNI) 설치: Calico
###### 노드 간 통신을 위해 가장 널리 쓰이는 Calico를 설치합니다. 이 작업은 Master 1번에서 한 번만 수행하면 됩니다.

# 1. Calico Operator 설치
kubectl create -f https://githubusercontent.com

# 2. Custom Resources 설치 (기본 Pod CIDR 192.168.0.0/16 기준)
kubectl create -f https://githubusercontent.com

###### 주의: 만약 kubeadm init 시 --pod-network-cidr을 10.244.0.0/16으로 설정했다면, custom-resources.yaml 파일을 다운로드하여 내부의 IP 대역을 수정한 후 적용해야 합니다.

# 3. 최종 상태 확인
###### CNI 설치 후 몇 분 정도 지나면 모든 노드의 상태가 Ready로 변합니다.

# 모든 노드 상태 확인
kubectl get nodes

# 모든 시스템 파드가 정상 실행 중인지 확인
kubectl get pods -A

# 4. [추가] 일반 사용자 권한 설정
###### kubectl 명령어를 root가 아닌 일반 계정에서도 쓰려면 각 마스터 노드에서 아래 설정을 해줍니다.

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

###### 이제 기본적인 HA 클러스터 구성이 완료되었습니다!
