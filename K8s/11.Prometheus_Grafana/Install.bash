###### IDC 실운영 환경에서 가장 표준적인 모니터링 조합은 kube-prometheus-stack입니다. 이는 Prometheus, Grafana, 그리고 K8s 메트릭 수집기들을 하나로 묶어 제공하는 패키지입니다.

# 1. Prometheus Stack 설치 (Helm)
###### 폐쇄망 환경이므로 인터넷이 되는 곳에서 차트를 미리 다운로드(helm pull)하여 반입해야 합니다.

#bash
# 1. 저장소 추가 및 차트 다운로드 (외부망)
helm repo add prometheus-community https://github.io
helm pull prometheus-community/kube-prometheus-stack --version 56.0.0

# 2. 설치 (내부망)
helm install monitoring ./kube-prometheus-stack-56.0.0.tgz \
  --namespace monitoring --create-namespace \
  -f monitoring-values.yaml

# 2. 실운영 최적화 설정 (monitoring-values.yaml)
###### HAProxy Ingress와 사설 인증서(Cert-manager)를 활용하여 모니터링 화면을 외부에 노출하는 설정입니다.

#yaml
prometheus:
  prometheusSpec:
    retention: 30d              # 데이터 보관 기간 (운영에 맞춰 조절)
    storageSpec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 50Gi     # 메트릭 저장 용량

grafana:
  ingress:
    enabled: true
    ingressClassName: haproxy   # HAProxy 사용
    annotations:
      cert-manager.io/cluster-issuer: "private-ca-issuer" # 사설 인증서
    hosts:
      - grafana.local           # 모니터링 접속 주소
    path: /
    tls:
      - secretName: grafana-tls
        hosts:
          - grafana.local

  adminPassword: "admin-password" # 초기 비밀번호 설정

# 3. 모니터링 핵심 구성 요소
## Prometheus: 노드와 파드에서 발생하는 CPU, 메모리, 네트워크 데이터를 수집하고 저장합니다.
## Grafana: 수집된 데이터를 그래프로 시각화합니다. (기본적으로 K8s 전용 대시보드가 수십 개 내장되어 있습니다.)
## Alertmanager: CPU 임계치 초과나 노드 다운 시 Slack, 이메일 등으로 알람을 보냅니다.
## Node Exporter: 각 물리 서버(OS)의 하드웨어 상태(디스크 사용량, 온도 등)를 수집합니다.

# 4. 확인 및 접속
###### 설치가 완료되면 브라우저에서 https://grafana.local로 접속합니다.
## Dashboard 메뉴에서 Kubernetes / Compute Resources / Cluster를 선택하면 클러스터 전체 자원 현황을 볼 수 있습니다.
## Alerts 메뉴에서 현재 발생한 경고 사항을 확인할 수 있습니다.

# 💡 실운영 모니터링 팁
## Persistence: 반드시 외부에 별도의 스토리지(NFS, Ceph 등)를 연결하여 Prometheus 데이터가 노드 재부팅 시 사라지지 않게 해야 합니다.
## Resource Limit: Prometheus는 메모리를 많이 소모하므로, values.yaml에서 Resource Limit을 넉넉히(최소 2~4GB) 설정하는 것이 좋습니다.
## 결정적인 팁: Grafana 대시보드 중 "Node Exporter Full" 대시보드를 추가하면 물리 서버의 상세한 하드웨어 상태까지 모니터링할 수 있어 장애 예측에 매우 유리합니다.
