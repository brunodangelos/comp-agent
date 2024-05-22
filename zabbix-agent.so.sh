#!/bin/bash

# Função para detectar a distribuição e a versão
detect_distribution_version() {
    # Verificar se /etc/os-release existe
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu)
                sudo wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu$(grep "DISTRIB_RELEASE" /etc/lsb-release | cut -d'=' -f2)_all.deb
                sudo dpkg -i zabbix-release_6.0-4+ubuntu$(grep "DISTRIB_RELEASE" /etc/lsb-release | cut -d'=' -f2)_all.deb
                sudo apt update
                sudo apt install zabbix-agent2 zabbix-agent2-plugin-*
                sudo sed -i s/Server\=.*/Server=$1/g /etc/zabbix/zabbix_agent2.conf
                sudo sed -i s/ServerActive\=.*/ServerActive=$1/g /etc/zabbix/zabbix_agent2.conf
                sudo sed -i 's/^Hostname=Zabbix server/# Hostname=Zabbix server/g' /etc/zabbix/zabbix_agent2.conf
                sudo sed -i 's/^# HostnameItem=system.hostname/HostnameItem=system.hostname/g' /etc/zabbix/zabbix_agent2.conf
                sudo systemctl enable zabbix-agent2
                sudo systemctl restart zabbix-agent2
                ;;
            debian)
                echo "Distribuição: $ID"
                echo "Versão: $VERSION_ID"
                # Fazer o download de arquivos diferentes com base na versão do Debian
                # Adicione os comandos correspondentes para Debian
                ;;
            rhel|centos|fedora)
                echo "Distribuição: $ID"
                echo "Versão: $VERSION_ID"
                # Fazer o download de arquivos diferentes com base na versão do Red Hat
                # Adicione os comandos correspondentes para Red Hat
                ;;
            *)
                echo "Distribuição não suportada: $ID"
                ;;
        esac
    else
        echo "Arquivo /etc/os-release não encontrado. Não é possível determinar a distribuição."
    fi
}

# Chamada da função para detecção
detect_distribution_version
