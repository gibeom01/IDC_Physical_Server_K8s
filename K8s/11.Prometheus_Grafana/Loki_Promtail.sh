# 1. 전체 시스템 로그 수집
###### ELK(Elasticsearch)보다 가볍고 Grafana와 통합이 완벽한 Loki를 사용

#bash
helm repo add grafana https://github.io
helm repo update

# Loki(저장소)와 Promtail(수집기) 설치
helm install loki-stack grafana/loki-stack \
  --namespace monitoring \
  --set promtail.enabled=true \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=50Gi

# 2. Grafana에서 로그 확인
###### 이미 설치된 Grafana UI(https://grafana.local)에 접속합니다.
## Configuration > Data Sources 메뉴로 이동합니다.
## Add data source를 누르고 Loki를 선택합니다.
## URL에 http://loki-stack.monitoring:3100을 입력하고 Save & Test를 누릅니다.
## Explore 탭에서 Log browser를 통해 특정 파드나 네임스페이스의 로그를 실시간으로 조회합니다

# 💡 실운영 로그 수집 핵심 팁
## Promtail: 모든 노드에 DaemonSet으로 설치되어 각 노드의 /var/log/pods에 쌓이는 로그를 실시간으로 가로채 Loki로 보냅니다. 별도의 에이전트 설정 없이도 모든 컨테이너 로그가 자동으로 수집됩니다.
## 로그 보관 기간(Retention): IDC 디스크 용량을 고려하여 Loki 설정에서 로그 보관 기간을 설정하세요. (예: 7일 또는 14일)
