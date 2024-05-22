#!/bin/bash

# Função para detectar o sistema operacional e executar atualizações
detect_and_configure_zabbix() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        if [[ $ID == "ubuntu" || $ID_LIKE == "ubuntu" ]]; then
            echo "Ubuntu detected."
            sudo wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu$(grep "DISTRIB_RELEASE" /etc/lsb-release | cut -d'=' -f2)_all.deb \
            && sudo dpkg -i zabbix-release_6.0-4+ubuntu$(grep "DISTRIB_RELEASE" /etc/lsb-release | cut -d'=' -f2)_all.deb \
            && sudo apt update \
            && sudo apt install zabbix-agent2 zabbix-agent2-plugin-* \
            && sudo sed -i "s/Server=.*/Server=$1/g" /etc/zabbix/zabbix_agent2.conf \
            && sudo sed -i "s/ServerActive=.*/ServerActive=$1/g" /etc/zabbix/zabbix_agent2.conf \
            && sudo sed -i 's/^Hostname=Zabbix server/# Hostname=Zabbix server/g' /etc/zabbix/zabbix_agent2.conf \
            && sudo sed -i 's/^# HostnameItem=system.hostname/HostnameItem=system.hostname/g' /etc/zabbix/zabbix_agent2.conf \
            && sudo systemctl enable zabbix-agent2 \
            && sudo systemctl restart zabbix-agent2
        elif [[ $ID == "debian" || $ID_LIKE == "debian" ]]; then
            echo "Debian detected."
            # Adicione os comandos correspondentes para o Debian aqui
        elif [[ $ID == "rhel" || $ID_LIKE == "rhel" ]]; then
            echo "Red Hat Enterprise Linux detected."
            # Adicione os comandos correspondentes para o Red Hat Enterprise Linux aqui
        else
            echo "Sistema operacional não suportado."
        fi
    else
        echo "Arquivo /etc/os-release não encontrado. Não é possível determinar o sistema operacional."
    fi
}

detect_and_configure_zabbix $1
