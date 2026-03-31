# ① 노드 및 시스템 파드 상태
###### 모든 노드가 Ready 상태이고, 네트워크/DNS 파드가 정상인지 확인합니다.

#bash
kubectl get nodes
kubectl get pods -n kube-system # coredns, calico 등이 Running인지 확인

# ② 인그레스 및 외부 접속 (HTTPS)
###### HAProxy와 Cert-manager가 조화를 이루어 SSL 인증서가 적용되었는지 확인합니다.

#bash
# 인증서 발급 완료 확인 (READY가 True여야 함)
kubectl get certificate -A

# 외부에서 접속 테스트 (도메인 기준)
curl -Iv https://myapp.local --cacert ca.crt

# ③ 로드밸런싱 및 고가용성 (HA)
###### 마스터 노드 한 대를 강제로 종료(sudo systemctl stop rke2-server)했을 때도 kubectl get nodes 명령어가 VIP를 통해 여전히 동작하는지 확인합니다.

# ④ 리소스 모니터링 (Grafana)
###### https://grafana.local에 접속하여 CPU/Memory 사용량이 임계치(80%) 이하인지, 로그(Loki)가 실시간으로 쌓이고 있는지 확인합니다.

# ⑤ 저장소 건전성 (PV/PVC)
###### Harbor나 Prometheus가 사용하는 디스크 볼륨이 정상적으로 마운트되어 있는지 확인합니다.

#bash
kubectl get pvc -A

# 실운영에 들어가기 전, kubectl get events -A 명령어를 통해 클러스터 내부에 숨겨진 경고(Warning) 메시지가 없는지 마지막으로 훑어보는 것이 장애 예방의 지름길
