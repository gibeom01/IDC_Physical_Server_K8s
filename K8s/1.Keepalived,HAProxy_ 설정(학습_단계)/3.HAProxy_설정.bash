###### 이 설정은 Master 1, 2 동일하게 적용합니다. K8s API 서버 기본 통신 포트인 6443(API)과 9345(Registration)를 모두 열어주고 리스닝하여 실제 노드들로 전달합니다.

#bash
frontend rke2-api
    bind *:6443             # 6443 포트로 들어오는 요청 수신
    mode tcp
    option tcplog
    default_backend rke2-api-backend

backend rke2-api-backend
    mode tcp
    option tcp-check
    balance roundrobin      # 순차적으로 부하 분산
    # 실제 마스터 노드들의 IP와 포트 (6443)
    server master1 192.168.0.10:6443 check
    server master2 192.168.0.11:6443 check

frontend rke2-register
    bind *:9345
    mode tcp
    option tcplog
    default_backend rke2-register-backend

backend rke2-register-backend
    mode tcp
    balance roundrobin
    server master1 192.168.0.10:9345 check
    server master2 192.168.0.11:9345 check
    