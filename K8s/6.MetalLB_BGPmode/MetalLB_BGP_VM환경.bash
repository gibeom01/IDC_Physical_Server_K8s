###### L3 스위치 같은 고가의 장비 없이도 소프트웨어 라우터 VM을 사용하여 BGP 환경을 완벽하게 흉내 낼 수 있습니다. 가장 대중적인 방법은 FRRouting(FRR)이라는 오픈소스 라우팅 소프트웨어를 별도의 VM에 설치하여 이를 "가상 스위치(Router)"로 사용하는 것입니다.
###### ESXi 환경에서 구성하는 구체적인 방법을 설명해 드립니다.

# 1. 가상 네트워크 구조 (Simulation)
## Router VM (FRR 설치): K8s 노드들과 BGP 세션을 맺을 가상 스위치 역할 (IP: 192.168.0.1)
## K8s 노드들: MetalLB를 통해 Router VM에 자신들이 가진 서비스 IP를 광고 (IP: 192.168.0.10~12)
## 사용자(Client): Router VM을 게이트웨이로 삼아 K8s 서비스 IP에 접속

# 2. Router VM 설정 (FRRouting)
## Ubuntu VM을 하나 만들고 FRR을 설치합니다.

#bash
# FRR 설치
sudo apt update && sudo apt install -y frr

# BGP 데몬 활성화 (/etc/frr/daemons 파일 수정)
# bgp=yes 로 변경 후 저장

# 서비스 재시작
sudo systemctl restart frr

## VTYSH(라우터 설정 쉘) 진입 후 설정:

#bash
sudo vtysh

# 설정 모드
conf t
router bgp 64500  # 스위치의 ASN
 bgp router-id 192.168.0.1
 # K8s 노드들을 피어로 등록
 neighbor 192.168.0.10 remote-as 64501
 neighbor 192.168.0.11 remote-as 64501
 neighbor 192.168.0.12 remote-as 64501
exit
write memory

# 3. MetalLB 설정 (K8s 클러스터)
## 이제 K8s 클러스터에서 MetalLB가 위에서 만든 Router VM과 대화하도록 설정합니다.

#yaml
apiVersion: metallb.io/v1beta2
kind: BGPPeer
metadata:
  name: frr-router
  namespace: metallb-system
spec:
  peerAddress: 192.168.0.1   # Router VM의 IP
  peerASN: 64500             # Router VM의 ASN
  myASN: 64501               # K8s 클러스터의 ASN
---
apiVersion: metallb.io/v1beta1
kind: BGPAdvertisement
metadata:
  name: bgp-adv
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool

# 4. BGP 모드 확인 (검증)
## 설정이 완료되면 Router VM에서 K8s 노드들로부터 경로 정보를 받았는지 확인합니다.

#bash
# Router VM의 vtysh에서 실행
show ip bgp summary  # 세션 연결 상태 확인 (State/PfxRcd 숫자가 올라가야 함)
show ip route        # MetalLB가 뿌린 서비스 IP(예: 192.168.0.200)가 경로에 있는지 확인

# 5. 이 방식의 장점
## ECMP 실습: Router VM 설정에서 maximum-paths 4 등을 주면, 트래픽이 여러 노드로 동시에 분산되는 진정한 로드밸런싱을 테스트할 수 있습니다.
## 무료: 고가의 L3 스위치 없이 리눅스 VM 한 대만으로 구성 가능합니다.
## 실무 유사성: 대규모 IDC에서도 장비만 물리 장비일 뿐, 설정 논리는 이와 100% 동일합니다.
