###### 이제 학습을 넘어 실제 서비스 운영 환경을 구축할 차례입니다. Rancher는 전체 클러스터를 관리하는 '관제탑' 역할을 하며, RKE2는 보안과 안정성이 강화된 '차세대 엔진' 역할을 합니다.
###### 실운영 환경에서는 Rancher를 별도의 전용 VM(또는 소규모 클러스터)에 설치하여 관리하는 것이 정석입니다.

# 1. Rancher용 전용 VM 준비
###### Rancher 서버는 관리 전용이므로 워커 노드와 분리하는 것이 좋습니다.
## 권장 사양: CPU 2 Core / RAM 4GB / Disk 40GB 이상
## OS: Ubuntu 22.04 LTS

# 2. 가장 쉬운 Rancher 설치 (Docker 방식)
###### 학습 및 소규모 운영 초기에는 Docker를 이용해 Rancher를 띄우는 것이 가장 빠르고 간편합니다.

#bash
# 1. Docker 설치
curl https://docker.com | sh

# 2. Rancher 컨테이너 실행 (인증서 자동 생성 포함)
sudo docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged \
  rancher/rancher:latest

###### 설치 후 브라우저에서 https://<Rancher-IP>로 접속하면 관리자 비밀번호 설정 화면이 나타납니다.

# 3. RKE2 클러스터 생성 (Rancher UI 활용)
###### 이제 Rancher 화면에서 클릭 몇 번으로 실운영급 RKE2 클러스터를 만들 수 있습니다.
## Cluster Management 메뉴 접속 → Create 클릭.
## RKE2/K3s 선택 → Custom (기존 물리 서버/VM 사용 시) 선택.
## Cluster Name 입력 (예: prod-cluster).
## Basics 설정:
### Kubernetes Version: 최신 안정 버전 선택.
### Container Network (CNI): 실운영은 Cilium 또는 Calico 권장.
## Registration 메뉴: 화면에 나오는 curl ... | sudo sh 형태의 명령어를 복사합니다.

# 4. 실제 서버에 RKE2 노드 추가
###### 복사한 명령어를 준비한 각 물리 서버(또는 VM)에서 실행하기만 하면 자동으로 RKE2가 설치되고 Rancher에 등록됩니다.
## Master 역할 노드: UI에서 etcd, Control Plane 체크박스를 선택하고 명령어 실행.
## Worker 역할 노드: Worker 체크박스만 선택하고 명령어 실행.

# 5. RKE2 + HAProxy + Keepalived 자동화 시나리오
###### 실운영 환경에서는 Rancher가 RKE2를 관리하더라도, 진입점(LB)은 여전히 중요합니다.
## HAProxy/Keepalived: 클러스터 외부(또는 전용 노드)에서 고정된 VIP를 유지합니다.
## RKE2 API: Rancher가 생성한 RKE2 노드들의 6443 포트를 HAProxy가 바라보게 설정합니다.
## Rancher 연동: Rancher UI에서 클러스터 주소를 해당 VIP로 등록하여 중앙 관리합니다.

# 💡 실운영 단계의 핵심 차이점
## 보안(Hardening): RKE2는 기본적으로 보안 설정(CIS Benchmark)이 적용되어 있어 Kubeadm보다 안전합니다.
## 업그레이드: Rancher UI에서 클릭 한 번으로 전체 클러스터의 K8s 버전을 중단 없이 업그레이드할 수 있습니다.
## 백업: etcd 데이터 백업 및 복구가 UI를 통해 자동화됩니다.

--

# 실운영 방식 (학습 후 진행)
## 1. Helm 설치 (없을 경우)
#bash
curl https://githubusercontent.com | bash

## 2. Rancher 저장소 추가 및 네임스페이스 생성
#bash
helm repo add rancher-stable https://rancher.com
helm repo update
kubectl create namespace cattle-system

## 3. Rancher 설치 (MetalLB LoadBalancer 타입 지정)
#bash
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.local \
  --set bootstrapPassword=admin-password123 \
  --set replicas=1 \
  --set service.type=LoadBalancer # MetalLB로부터 IP를 받기 위해 설정

## 4.단계: 접속 주소 확인 및 접속 (설치가 완료되면 MetalLB가 Rancher 서비스에 할당한 외부 IP를 확인)
#bash
kubectl get svc -n cattle-system rancher