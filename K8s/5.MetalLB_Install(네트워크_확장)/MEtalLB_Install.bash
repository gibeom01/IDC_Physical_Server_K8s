###### IDC 물리적 서버 환경의 꽃인 MetalLB 설치 단계입니다. MetalLB가 있어야 Type: LoadBalancer 서비스를 생성했을 때 클라우드처럼 외부 IP를 자동으로 할당받을 수 있습니다.
###### 학습 단계에서는 가장 설정이 간편한 L2 모드(Layer 2) 방식을 추천합니다.

# 1. ARP 모드 활성화 (Kube-Proxy 설정 변경)
###### MetalLB의 L2 모드를 사용하려면 K8s의 strictARP 설정이 true여야 합니다.

#bash
# 현재 설정을 편집기로 엽니다
kubectl edit configmap -n kube-system kube-proxy

###### 편집기에서 아래 내용을 찾아 false를 true로 수정하고 저장하세요.

#yaml
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs" # 또는 빈값일 수 있음
ipvs:
  strictARP: true # 이 부분을 true로 변경

# 2. MetalLB 설치 (Manifest 방식)
###### 공식 저장소에서 최신 매니페스트를 적용합니다.

#bash
# MetalLB 네임스페이스 및 컴포넌트 설치
kubectl apply -f https://githubusercontent.com

###### 설치 후 모든 파드가 Running 상태가 될 때까지 약 1~2분 기다려주세요. (kubectl get pods -n metallb-system)

# 3. IP 주소 풀(Pool) 및 L2 광고 설정
###### 이제 서비스에 할당할 외부 IP 대역을 지정해야 합니다. ESXi 네트워크 대역 중 사용하지 않는 IP 범위를 선택하세요. (예: 192.168.0.200 ~ 192.168.0.210)

#yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.0.200-192.168.0.210 # 본인의 환경에 맞는 미사용 IP 대역 입력
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-adv
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool

#bash
kubectl apply -f ip-pool.yaml

# 4. 제대로 작동하는지 테스트 (Nginx 배포)
###### 실제로 로드밸런서 IP가 할당되는지 확인해 봅니다.
#bash
# 테스트용 Nginx 배포
kubectl create deployment nginx-test --image=nginx
kubectl expose deployment nginx-test --port=80 --type=LoadBalancer

#bash
kubectl get svc

###### 결과 화면의 EXTERNAL-IP 항목에 아까 설정한 범위 중 하나(예: 192.168.0.200)가 찍혀 있다면 성공입니다! 이제 브라우저에서 해당 IP로 접속하면 Nginx 화면이 뜰 것입니다.

# 💡 학습 팁
## IP 충돌 주의: MetalLB에 할당한 IP 대역은 공유기(DHCP)나 다른 서버가 사용 중이지 않은 깨끗한 대역이어야 합니다.
## 동작 원리: 외부에서 해당 VIP로 요청이 오면, MetalLB가 "그 IP는 지금 내 노드(Master/Worker 중 하나)가 가지고 있어!"라고 ARP 응답을 보내 트래픽을 가로챕니다.

--

# 실운영 방식 (학습 후 진행)

## MetalLB 설치 (서비스용 IP 확보)
### 1. MetalLB 매니페스트 적용
#bash
# MetalLB 설치
kubectl apply -f https://githubusercontent.com

# 설치 확인 (모든 파드가 Running이 될 때까지 대기)
kubectl get pods -n metallb-system

### 2. IP 주소 풀 및 광고 설정 (metallb-config.yaml)
#yaml
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.0.200-192.168.0.210 # 본인 환경에 맞는 IP 대역
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-adv
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF
