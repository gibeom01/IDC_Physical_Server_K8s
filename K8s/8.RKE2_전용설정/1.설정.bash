###### RKE2는 kubeadm처럼 명령행 인자(Flags)를 길게 나열하는 대신, /etc/rancher/rke2/config.yaml 파일 하나로 모든 설정을 관리합니다. 이 방식은 설정의 형상 관리가 가능하고 재설치가 간편하여 실운영 환경에서 매우 강력한 장점을 가집니다.
###### 실운영 수준의 마스터 노드(Server)용 config.yaml 핵심 설정 예시를 설명해 드립니다.

# 1. RKE2 주요 설정 파일 생성 (/etc/rancher/rke2/config.yaml) 
##### 모든 마스터 노드에서 아래와 같은 구조로 파일을 작성합니다. (파일이 없으면 직접 생성해야 합니다.)

#yaml
# 1. 고가용성(HA) 및 접속 정보
tls-san:
  - "192.168.0.100"          # Keepalived로 만든 VIP (필수)
  - "://example.com"    # 외부 접속용 도메인이 있다면 추가
write-kubeconfig-mode: "0644" # 일반 사용자도 kubectl을 사용할 수 있게 권한 설정

# 2. 네트워크 및 CNI 설정
cni:
  - cilium                   # 실운영 권장 (또는 calico)
disable-kube-proxy: true     # Cilium 사용 시 성능 향상을 위해 false/true 선택
node-ip: "192.168.0.10"      # 해당 노드의 실제 물리 IP

# 3. 데이터베이스 (HA 구성 시 필수)
# 첫 번째 마스터는 생략하거나 초기화 후 설정, 두 번째부터는 아래 주소 참조
# server: https://192.168.0.10:9345 

# 4. 컴포넌트 비활성화 (커스텀 컨트롤을 위해)
disable:
  - rke2-ingress-nginx       # 기본 Nginx Ingress 대신 HAProxy 등을 쓸 경우 제외
  - rke2-metrics-server      # 별도의 모니터링 도구를 쓸 경우 제외

# 5. 보안 및 감사(Audit) 로그 (운영 필수)
kube-apiserver-arg:
  - "audit-log-path=/var/lib/rancher/rke2/server/logs/audit.log"
  - "audit-log-maxlen=100"
  - "audit-log-maxbackup=10"

# 2. 설정 적용 및 실행 순서
## 디렉토리 생성: sudo mkdir -p /etc/rancher/rke2
## 파일 작성: 위 내용을 sudo vi /etc/rancher/rke2/config.yaml에 저장.
## 서비스 실행:
#bash
# RKE2 서버 설치 (바이너리 다운로드)
curl -sfL https://rke2.io | sudo sh

# 서비스 활성화 및 시작
sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service

# 3. 실운영 커스텀의 핵심 포인트
## ① tls-san (가장 중요)
###### RKE2는 보안을 위해 API 서버 인증서에 허용된 IP/도메인만 접속을 허용합니다. HAProxy VIP를 여기에 넣지 않으면, 나중에 VIP를 통해 kubectl 명령어를 날릴 때 인증서 오류(x509: certificate is valid for...)가 발생합니다.
## ② token 관리
###### 마스터 노드 간 혹은 워커 노드 조인을 위해 고정된 토큰을 미리 정의할 수 있습니다.
#yaml
token: "my-shared-secret-token" # 임의의 복잡한 문자열

###### 이렇게 하면 매번 생성된 토큰을 확인하러 서버에 들어갈 필요 없이 자동화 도구(Ansible 등)로 노드를 즉시 확장할 수 있습니다.
## ③ 컨테이너 레지스트리 미러링
###### IDC 폐쇄망 환경이거나 속도를 높이고 싶다면 별도의 registries.yaml을 설정하여 내부 Docker Registry(Harbor 등)를 바라보게 할 수 있습니다.

# 4. 설정 변경 시 주의사항
###### config.yaml을 수정한 후에는 반드시 서비스를 재시작해야 적용됩니다.
#bash
sudo systemctl restart rke2-server
