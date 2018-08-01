#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NORMAL='\033[0m'
UNDERLINE='\033[4m'
F_NORMAL='\033[0m'

tput sgr0 

arrayDontInstallPackage=()
selectedUser="0"

# Проверяет установлены ли необходимые пакеты (LAMP)
function checkInstallPackage {
    package=`dpkg -s $1 . 2>/dev/null | grep "Status" `
    if [ -n "$package" ]
    then
        echo -en "\n$1 ${GREEN}установлен${NORMAL}"
    else
        echo -en "\n$1 ${RED}не установлен${NORMAL}"
        arrayDontInstallPackage[${#arrayDontInstallPackage[*]}]=$1
    fi
}

# Метод устанавливающий пакеты из списка
function installPackageOutList {
    for item in ${arrayDontInstallPackage[*]}
    do 
        apt-get install $item
    done
}

# Функция проверяющая существует ли пользователь(его домашняя папка)
function checkUser {
    [ -d /home/$1 ] 
}

# Запрос об обновление пакетов
function requestUpdatePackage {
    echo -en "${UNDERLINE}Обновить пакеты (y|n)?${F_NORMAL}"
    read accept
    if [[ $accept == "y" || $accept == "н" ]]
    then
        echo -en "\n${UNDERLINE}Запускаю процес обновления пакетов:${F_NORMAL}"
        apt-get update
        apt-get upgrade
    fi
}

function requestCreateDirectories {
    echo -en "${UNDERLINE}Введите имя пользователя:${F_NORMAL}"
    read user
    if checkUser $user;
    then
        selectedUser=$user
        echo -en "${UNDERLINE}Создание папок...${F_NORMAL}"
        mkdir sites
        mkdir mail
        mkdir bashScripts;
        mkdir logs;
    else
        echo -en "${UNDERLINE}Данного пользователя не существует${F_NORMAL}\n"
        requestCreateDirectories;
    fi
}

# Запрос об установки пакетов
function requestInstallPackage {
    # Проверка установки пакетов
    echo -en "\n${UNDERLINE}Проверка установки пакетов:${F_NORMAL}"
    checkInstallPackage sudo
    checkInstallPackage apache2
    checkInstallPackage php
    checkInstallPackage php-mysql
    checkInstallPackage libapache2-mod-php
    checkInstallPackage php-mbstring
    checkInstallPackage php-zip 
    checkInstallPackage php-gd
    checkInstallPackage mysql-server
    checkInstallPackage mysql-client
    checkInstallPackage mysql-common
    checkInstallPackage unzip

    # Проверка установлены ли все пакеты
    if [[ ${#arrayDontInstallPackage[*]} != 0 ]]
    then
        echo -en "\n${UNDERLINE}Некоторые пакеты не установлены, установить их(y|n)?${F_NORMAL}"
        read acceptInstall
        if [[ $acceptInstall == "y" || $acceptInstall == "н" ]]
        then
            installPackageOutList
        else
            echo -en "${UNDERLINE}Отмена установки${F_NORMAL}\n"
            exit
        fi
    fi
}

function getScripts {
    if [[ $selectedUser != "0" ]]
    then
        if [[ -d /home/$selectedUser/bashScripts ]]
        then
            echo -en "\n${UNDERLINE}Скачивание архива...${F_NORMAL}"
            cd /home/$selectedUser/bashScripts
            wget https://github.com/mafof/AutomationScriptsLinuxWebServer/archive/master.zip . 2>/dev/null
            unzip -qq -u -j master.zip
            rm  README.md
            rm master.zip
            echo -en "${GREEN}[OK]${NORMAL}"
        fi
    else
        echo -en "\n${UNDERLINE}Введите имя пользователя:${F_NORMAL}"
        read user
        if checkUser $user;
        then
            getScripts
        else
            echo -en "\n${RED}Неправильное имя пользователя${NORMAL}"
            getScripts
        fi
    fi
}

# Главный метод
function main {
    requestUpdatePackage # Обновление пакетов
    requestCreateDirectories # Создавать ли окружение(папки)
    requestInstallPackage # Проверка установки нужных пакетов
    getScripts # Скачивание всех скриптов и перемещение их в папку bashScripts
    echo -en "\n${UNDERLINE}Скрипт отработал успешно, для добовление сайтов воспользуйтесь файлом createSite.sh в директории /home/$selectedUser/bashScripts ${F_NORMAL}\n"
}
main