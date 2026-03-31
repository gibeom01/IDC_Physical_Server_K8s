###### Kubernetes의 심장인 etcd는 모든 클러스터의 상태 데이터(노드, 파드, 설정, 보안 등)가 저장되는 유일한 장소입니다. etcd가 유실되면 클러스터 전체가 파괴된 것과 다름없으므로, 실운영 환경에서 백업과 복구 전략은 최우선 순위입니다.
###### RKE2 환경에서 제공하는 자동화 기능과 수동 백업 방법을 나누어 설명해 드립니다.

# 1. RKE2 자동 백업 설정 (권장)
##### RKE2는 자체적으로 etcd 스냅샷(Snapshot) 기능을 내장하고 있습니다. /etc/rancher/rke2/config.yaml에 설정을 추가하여 자동화합니다.

#yaml (/etc/rancher/rke2/config.yaml 설정 확인)
# etcd 자동 백업 설정
etcd-snapshot-schedule-cron: "0 */6 * * *" # 6시간마다 백업
etcd-snapshot-retention: 28                # 최근 28개(일주일치) 백업 유지
etcd-snapshot-dir: "/var/lib/rancher/rke2/server/db/snapshots" # 백업 경로

###### 팁: 백업 경로(etcd-snapshot-dir)를 NFS나 별도의 외부 스토리지로 마운트하면, 물리 서버 자체가 파손되어도 데이터를 살릴 수 있습니다.

# 2. 수동 백업 방법 (즉시 백업)
###### 점검이나 업데이트 전, 즉시 백업이 필요할 때 사용합니다.

#bash (백업 파일 생성 확인)
# RKE2 명령어로 즉시 스냅샷 생성
sudo rke2 etcd-snapshot save --name pre-upgrade-backup

# 생성 확인
sudo rke2 etcd-snapshot list

# 설정 후 서비스 재시작 후 실제 파일이 생성되는지 확인
sudo systemctl restart rke2-server

# 3. 장애 시나리오별 복구 전략 (Restore)

## 시나리오 A: 데이터 오설정으로 인한 롤백 (데이터만 복구)
###### 클러스터는 살아있으나 설정 실수로 이전 상태로 되돌려야 할 때입니다.
### A-1.모든 노드의 RKE2 서비스 중단: sudo systemctl stop rke2-server
### A-2. 첫 번째 마스터 노드에서 복구 실행:

#bash
sudo rke2 server \
  --cluster-reset \
  --cluster-reset-restore-path=<스냅샷_파일_경로>

### A-3. 서비스 재시작: sudo systemctl start rke2-server
### A-4. 다른 마스터 노드들: DB 디렉토리를 지우고 서비스를 재시작하여 첫 번째 노드로부터 데이터를 동기화받게 합니다.

## 시나리오 B: 전체 마스터 노드 파손 (완전 복구)
###### 서버 하드웨어 장애 등으로 마스터 노드를 새로 설치해야 할 때입니다.
### B-1. 새 서버에 RKE2를 동일한 버전으로 설치합니다.
### B-2. 외부에 보관했던 etcd 스냅샷 파일과 /etc/rancher/rke2/config.yaml을 새 서버로 가져옵니다.
### B-3. 시나리오 A와 동일하게 --cluster-reset 옵션으로 복구 후 클러스터를 재구성합니다.

# 4. 실운영을 위한 3단계 보안 장치
## 다중화(HA): 최소 3대의 마스터 노드를 구성하여 1대가 죽어도 서비스가 유지되게 합니다.
## 오프사이트 백업: 백업된 스냅샷 파일을 주기적으로 다른 물리적 위치(다른 IDC나 클라우드 스토리지)로 전송합니다.
## 복구 훈련: 분기에 한 번은 테스트 환경에서 실제 백업 파일로 복구가 되는지 시뮬레이션해 봅니다.
