###### RKE2는 기본적으로 Nginx Ingress Controller를 내장하고 있습니다. 이를 비활성화하고 고성능 HAProxy Ingress로 교체하는 것은 대규모 트래픽 처리가 필요한 실운영 환경에서 매우 탁월한 선택입니다.
###### 단계별 적용 방법을 안내해 드립니다.

# 1. RKE2 기본 Nginx 비활성화
###### 먼저 RKE2 설치 시 내장된 Nginx가 뜨지 않도록 설정 파일(config.yaml)을 수정해야 합니다.

#yaml (/etc/rancher/rke2/config.yaml 수정:)
disable:
  - rke2-ingress-nginx  # 내장된 Nginx 배포 방지

###### 수정 후 RKE2 서비스를 재시작합니다. (sudo systemctl restart rke2-server)

# 2. Helm을 통한 HAProxy Ingress 설치
###### Kubernetes 패키지 관리 도구인 Helm을 사용하는 것이 가장 관리하기 편합니다. (Helm이 없다면 먼저 설치하세요: curl https://githubusercontent.com | bash)

#bash (HAProxy 공식 차트 추가)
helm repo add haproxy-ingress https://github.io
helm repo update


#bash (설치 실행 (핵심 설정 포함))
helm install haproxy-ingress haproxy-ingress/haproxy-ingress \
  --namespace ingress-controller --create-namespace \
  --set controller.kind=DaemonSet \
  --set controller.ingressClass=haproxy \
  --set controller.service.type=LoadBalancer

## DaemonSet: 모든 노드에 HAProxy를 띄워 가용성을 높입니다.
## hostNetwork=true: 노드의 80/443 포트를 직접 점유하여 성능을 극대화합니다. (MetalLB 없이도 노드 IP로 바로 접속 가능)

# 2-1. 할당된 외부 IP 확인
#bash
kubectl get svc -n ingress-controller haproxy-ingress

# 3. HAProxy Ingress 설정 최적화 (Values.yaml)
###### 실운영에서는 아래와 같은 세부 설정을 values.yaml 파일로 관리하는 것이 좋습니다.

#yaml
controller:
  config:
    # 성능 및 보안 최적화
    max-connections: "50000"
    ssl-redirect: "true"
    hsts: "true"
    timeout-client: "50s"
    timeout-server: "50s"
  resources:
    requests:
      cpu: "500m"
      memory: "512Mi"

#4. MetalLB와의 연동 (선택 사항)
###### 만약 hostNetwork 대신 MetalLB로부터 할당받은 가상 IP(VIP)를 Ingress 진입점으로 쓰고 싶다면, 위 설치 명령에서 설정을 변경합니다.

controller.hostNetwork=false
controller.service.type=LoadBalancer

###### 이렇게 하면 MetalLB가 HAProxy Ingress에 192.168.0.201 같은 외부 IP를 할당해 줍니다.

# 5. 교체 확인 테스트
###### 이제 Ingress 리소스를 생성할 때 ingressClassName을 haproxy로 지정하면 됩니다.

#yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
spec:
  ingressClassName: haproxy  # 핵심!
  rules:
  - host: ://example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80

# 💡 왜 HAProxy Ingress인가?
## 성능: Nginx 대비 복잡한 라우팅 규칙에서도 낮은 CPU 점유율과 빠른 응답 속도를 유지합니다.
## 동적 설정: 백엔드 서버가 추가/삭제될 때 설정 리로드(Reload) 없이 즉시 반영하는 기능이 매우 강력합니다.
## 가시성: 내장된 통계 페이지(Stats Page)를 통해 트래픽 현황을 한눈에 볼 수 있습니다.
