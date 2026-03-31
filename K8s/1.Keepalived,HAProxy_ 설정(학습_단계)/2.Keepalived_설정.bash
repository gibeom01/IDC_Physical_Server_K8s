# Keepalived 설정 (/etc/keepalived/keepalived.conf)
###### 이 설정은 Master 1 기준입니다. Master 2에서는 state를 BACKUP으로, priority를 100으로 낮춰서 설정하세요.

#bash 도구 설치 (모든 로드밸런서 노드)
sudo apt update && sudo apt install -y haproxy keepalived

#bash Keepalived 설정 - Master 1 (/etc/keepalived/keepalived.conf)
vrrp_script check_haproxy {
    script "killall -0 haproxy" # HAProxy 프로세스가 살아있는지 확인
    interval 2
    weight 2
}

vrrp_instance VI_1 {
    state MASTER            # 2번 서버는 BACKUP으로 설정
    interface ens160        # 본인의 네트워크 인터페이스명 (ip addr로 확인)
    virtual_router_id 51    # 동일 네트워크 내 유일한 값
    priority 101            # 2번 서버는 100으로 설정하여 우선순위 차등
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass 1234       # 패스워드 설정
    }

    virtual_ipaddress {
        192.168.0.100       # 사용할 가상 IP(VIP)
    }

    track_script {
        check_haproxy
    }
}
