###### IDC 물리적 서버(ESXi) 환경에서 가장 먼저 구성해야 할 네트워크 설계도와 방화벽 허용 목록입니다. 이 기초가 흔들리면 나중에 노드가 연결되지 않거나 VIP가 작동하지 않는 등 찾기 힘든 오류가 발생합니다.

# 1. IP 주소 설계 (IP Address Planning)
###### 서버 대수가 적더라도 용도별로 대역을 명확히 나누는 것이 운영에 유리합니다. (예시 대역: 192.168.0.0/24)

용도	         IP 주소 예시	        개수	  비고
K8s API VIP	    192.168.0.100	       1개	    Keepalived + HAProxy용 (고정)
Master 노드	     192.168.0.10 ~ 12	    3개	     실제 마스터 서버 IP
Worker 노드	     192.168.0.20 ~ 29	    10개	 실제 워커 서버 IP
MetalLB Pool	 192.168.0.200 ~ 210   11개	    서비스 노출용 (미사용 대역 필수)
Harbor/Grafana	 192.168.0.200 등	    -	    MetalLB가 할당할 서비스 IP

# 2. 네트워크 필수 사전 설정 (ESXi 및 OS)
## ESXi vSwitch 설정:
###### Promiscuous Mode (무차별 모드): Accept (Keepalived VIP 작동용)
###### MAC Address Changes: Accept
###### Forged Transmits: Accept
## OS 고정 IP 설정 (Static IP):
###### 모든 노드는 DHCP가 아닌 고정 IP를 사용해야 합니다. (/etc/netplan/ 등 수정)
## DNS/Hosts 설정:
###### 폐쇄망이라면 모든 노드의 /etc/hosts에 각 노드의 호스트명과 IP를 미리 등록해두면 통신이 원활합니다.

# 3. 방화벽(Firewall) 허용 포트 리스트
###### RKE2 및 K8s 운영을 위해 리눅스 방화벽(ufw 또는 firewalld)에서 최소한 다음 포트들을 열어주어야 합니다.

## A. 마스터(Server) 노드 공통
###### 6443/tcp: Kubernetes API Server (kubectl 통신)
###### 9345/tcp: RKE2 Cluster Register (노드 조인 시 필수)
###### 2379-2380/tcp: etcd 클라이언트 및 피어 통신
###### 10250/tcp: Kubelet API (로그 확인, exec 명령 등)
###### CNI 포트 (Calico/Cilium):
###### 179/tcp: BGP 통신 (Calico 사용 시)
###### 4789/udp: VXLAN 오버레이 네트워크 (기본)

## B. 워커(Agent) 노드 공통
###### 10250/tcp: Kubelet API
###### 30000-32767/tcp: NodePort 서비스용 (필요 시)
###### 80, 443/tcp: Ingress 트래픽 진입로

## C. 고가용성(HA) 도구용
###### VRRP (Protocol 112): Keepalived 간 상태 체크용 (포트가 아닌 프로토콜 허용 필요)

# 4. 실전 방화벽 설정 명령어 (Ubuntu ufw 기준)
###### 모든 노드에서 가장 안전하게 시작하려면 다음과 같이 입력하세요.

#bash
# 기본 정책 설정
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH 허용
sudo ufw allow 22/tcp

# K8s 내부 통신 (노드 간 IP 대역 통째로 허용 - 추천)
sudo ufw allow from 192.168.0.0/24

# VRRP (Keepalived) 프로토콜 허용
sudo ufw allow in on ens160 to any proto vrrp

# 방화벽 활성화
sudo ufw enable

# 💡 전문가 팁: "시작은 방화벽 Off"
###### 처음 설치 단계에서는 방화벽을 잠시 끄고(sudo ufw disable) 클러스터가 정상적으로 Ready 상태가 되는지 먼저 확인하세요. 그 후 하나씩 포트를 열며 보안을 강화하는 것이 디버깅 시간을 90% 단축하는 비결입니다.
