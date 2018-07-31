#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NORMAL='\033[0m'
UNDERLINE='\033[4m'
F_NORMAL='\033[0m'

tput sgr0 

arrayDontInstallPackage=()

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
function checkUser { [ -d /home/$1 ] }

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
        echo -en "${UNDERLINE}Создание папок...${F_NORMAL}"
        mkdir sites
        mkdir mail
        mkdir scripts;
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

# Главный метод
function main {
    requestUpdatePackage # Обновление пакетов (1 шаг)
    requestCreateDirectories # Создавать ли окружение(папки) (2 шаг)
    requestInstallPackage # Проверка установки нужных пакетов (3 шаг)
    # Установка пакета git с клонированием репозитория с конфигами(либо через wget) (4 шаг)
    echo -en "${UNDERLINE}Скрипт отработал успешно, для добовление сайтов воспользуйтесь файлом `createSite.sh` в директории ${F_NORMAL}"
}
main