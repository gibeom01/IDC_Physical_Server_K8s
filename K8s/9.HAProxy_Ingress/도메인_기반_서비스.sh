# 1. 테스트용 서비스 배포
#bash
kubectl create deployment web-demo --image=nginx
kubectl expose deployment web-demo --port=80

# 2. 인그레스(Ingress) 리소스 생성 (ingress.yaml)
#yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    # HAProxy 전용 설정 (필요 시 추가)
    haproxy.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: haproxy  # 반드시 설치한 클래스명 지정
  rules:
  - host: myapp.local        # 연결할 도메인
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-demo
            port:
              number: 80

# 3. 접속 확인 (DNS/Hosts 설정)
###### 실제 도메인을 구매하기 전이라면, 관리용 PC의 hosts 파일을 수정하여 테스트합니다.
## Windows 경로: C:\Windows\System32\drivers\etc\hosts
## 추가 내용: 192.168.0.201 myapp.local (MetalLB가 준 IP 입력)
###### 이제 브라우저에서 http://myapp.local로 접속하면 Nginx 화면이 뜹니다.

# 💡 고성능 운영을 위한 팁
## Sticky Session: 세션 유지가 필요한 앱이라면 haproxy.ingress.kubernetes.io/affinity: "cookie" 어노테이션을 추가하세요.
## Stats 페이지: HAProxy가 트래픽을 어떻게 처리하는지 실시간으로 보려면 controller.stats.enabled=true 설정을 켜서 통계 화면을 볼 수 있습니다.
