# 1. Cert-manager 설치

#bash
helm repo add jetstack https://jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set installCRDs=true

# 2. 사설 ClusterIssuer 생성 (ca-issuer.yaml)
###### 앞서 만든 사설 CA Secret(tls-ca-key-pair)이 있다고 가정합니다.

#yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: private-ca-issuer
spec:
  ca:
    secretName: tls-ca-key-pair

###### 적용: kubectl apply -f ca-issuer.yaml

# 3. HAProxy Ingress에 SSL 적용 (myapp-ingress.yaml)

#yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-web-ingress
  annotations:
    cert-manager.io/cluster-issuer: "private-ca-issuer"
    haproxy.ingress.kubernetes.io/ssl-redirect: "true" # HTTP 접속 시 HTTPS로 강제 리다이렉트
spec:
  ingressClassName: haproxy
  tls:
  - hosts:
    - myapp.local
    secretName: myapp-tls-cert # 인증서가 자동 생성되어 저장될 Secret 이름
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-demo
            port:
              number: 80
              

# 💡 실운영 로그 수집 핵심 팁
## HTTPS 인증서: 브라우저에서 myapp.local 접속 시 "안전하지 않음"이 뜨면, 아까 만든 사설 ca.crt를 PC의 신뢰할 수 있는 루트 인증 기관에 등록하면 해결됩니다.
