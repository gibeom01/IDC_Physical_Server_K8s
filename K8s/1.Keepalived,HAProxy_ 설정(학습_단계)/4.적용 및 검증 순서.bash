# 1. 적용 및 검증 순서

## 1-1. 서비스 시작: 두 서버 모두에서 서비스를 실행합니다.
sudo systemctl restart keepalived haproxy
sudo systemctl enable keepalived haproxy

## 1-2. VIP 확인: Master 1에서 ip addr 명령어를 입력했을 때 192.168.0.100이 인터페이스에 할당되어 있는지 확인합니다.
ip addr show ens160 | grep 192.168.0.100

## 1-3. Failover 테스트: Master 1의 전원을 끄거나 서비스를 중지했을 때, Master 2로 VIP가 즉시 이동하는지 ping 192.168.0.100으로 테스트합니다.

# 4. Kubeadm 초기화 시 활용
###### 위 구성이 완료되면, 클러스터 초기화 명령에 해당 VIP를 넣습니다.
sudo kubeadm init --control-plane-endpoint "192.168.0.100:6443" --upload-certs ...

## 중요 체크: ESXi 가상 스위치 설정에서 '무차별 모드(Promiscuous Mode)'를 허용(Accept)으로 변경하셨나요? 이 설정이 꺼져 있으면 VIP 패킷이 정상적으로 전달되지 않을 수 있습니다.

# 💡 실운영을 위한 추가 팁
## 1. 커널 포워딩 활성화: HAProxy가 부하 분산을 원활히 하도록 커널 파라미터를 허용해 줍니다.
#bash
echo "net.ipv4.ip_nonlocal_bind = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

## 2. 로그 모니터링: VIP가 왔다 갔다 하거나 연결이 안 될 때 아래 명령어로 원인을 찾을 수 있습니다.
sudo journalctl -u keepalived -f
sudo tail -f /var/log/haproxy.log
