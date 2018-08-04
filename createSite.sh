#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NORMAL='\033[0m'
UNDERLINE='\033[4m'
F_NORMAL='\033[0m'

PATH_NGINX=("/etc/nginx/sites-available" "/etc/nginx/sites-enabled")
PATH_APACHE=("/etc/apache2/sites-available" "/etc/apache2/sites-enabled")
PATH_DIRECTORY="null" # Путь до директории где распологается сайт

SELECT_SERVER="null"
SELECT_USER="null"

NAME_SITE="null"

tput sgr0 

# Функция проверяющая существует ли пользователь(его домашняя папка)
function checkUser {
    [ -d /home/$1 ] 
}

function getIp {
    ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'
}

# Метод создающий конфигурационный файл apache || nginx
function createConfig {
    if [[ $SELECT_SERVER == "apache" ]]
    then
    
        export CONFIGAPACHE=$(cat <<END
<VirtualHost *:80>
    ServerName $1
    DocumentRoot $PATH_DIRECTORY

    ErrorLog /home/$SELECT_USER/logs/$1/error.log
    CustomLog /home/$SELECT_USER/logs/$1/error.log combined
</VirtualHost>
END
    );
    
        echo "$CONFIGAPACHE" >> "${PATH_APACHE[0]}/$1.conf"
        ln -s "${PATH_APACHE[0]}/$1.conf" "${PATH_APACHE[1]}/$1.conf"
    
    elif [[ $SELECT_SERVER == "nginx" ]]
    then
        echo -en "${RED}Поддержка создания конфигурационного файла для nginx в разработке${NORMAL}"
        # Добавить откат действий
        exit
    fi
}

# Метод добовляющий в файл hosts доменное имя
function appendDomenToHostsFile {
    echo -en "\n${UNDERLINE}Укажите доменное имя:${F_NORMAL}"
    read domenSite

    echo -en "\n${UNDERLINE}Доменное имя: $domenSite, подтвердить?(y|n)${F_NORMAL}"
    read selectAccept
    if [[ $selectAccept != "n" || $selectAccept != "т" ]]
    then
        echo $(getIp)  $domenSite >> /etc/hosts
        echo -en "\n${UNDERLINE}Сайт успешно создан.\nДиректория сайта /home/$SELECT_USER/$NAME_SITE\nДиректория логов /home/$SELECT_USER/logs/$NAME_SITE\n ${F_NORMLA}"
    fi
}

function createSite {
    echo -en "\n${UNDERLINE}Укажите название сайта:${F_NORMAL}"
    read nameSites
    
    echo -en "\n${UNDERLINE}Создание директории сайта...${F_NORMAL}"
    PATH_DIRECTORY="/home/$SELECT_USER/sites/$nameSites"
    mkdir /home/$SELECT_USER/sites/$nameSites
    mkdir /home/$SELECT_USER/logs/$nameSites
    echo -en "${GREEN}[OK]${NORMAL}\n"

    echo -en "${UNDERLINE}Создание конфигурационного файла...${F_NORMAL}"
    createConfig $nameSites
    NAME_SITE=$nameSites
    echo -en "${GREEN}[OK]${NORMAL}\n"

    if [[ $SELECT_SERVER == "apache" ]]
    then
        echo -en "${UNDERLINE}Перезагрузка сервисов...${F_NORMAL}"
        service apache2 restart
        echo -en "${GREEN}[OK]${NORMAL}\n"
    elif [[ $SELECT_SERVER == "nginx" ]]
    then
        echo -en "${RED}Поддержка создания конфигурационного файла для nginx в разработке${NORMAL}"
        # Добавить откат действий
        exit
    fi
    appendDomenToHostsFile

}

function removeSite {
    echo -en ""   
}

function editSite {
    echo -en ""
}

function requestSelectUser {
    echo -en "${UNDERLINE}Введите имя пользователя:${F_NORMAL}"
    read user
    if checkUser $user;
    then
        SELECT_USER=$user
    else
        echo -en "${UNDERLINE}Данного пользователя не существует${F_NORMAL}\n"
        requestSelectUser;
    fi
}

function requestDoIt {
    echo -en "\n${UNDERLINE}Выберите что нужно сделать:\n1.Создать сайт\n2.Изменить сайт${F_NORMAL}\n"
    read doChoice

    case $doChoice in
        1)
            createSite;;
        2)
            editSite;;
    esac
}

# Метод выбирающий на каком пакете создать сайт (nginx || apache)
function requestSelectServer {
    echo -en "\n${UNDERLINE}Выберите серверный пакет:\n1.nginx\n2.apache\n${F_NORMAL}"
    read selectServer
    SELECT_SERVER=selectServer
    if [[ $selectServer == "1" ]]
    then
        SELECT_SERVER="nginx"
    elif [[ $selectServer == "2" ]]
    then
        SELECT_SERVER="apache"
    fi
    
    echo -en "${UNDERLINE}Выбран $SELECT_SERVER, подтвердить?(y|n)${F_NORMAL}"
    read selectAccept
    
    if [[ $selectAccept == "n" || $selectAccept == "т" ]]
    then
        requestSelectServer
    fi
}


function main {
    requestSelectUser # Выбор пользователя
    requestSelectServer # Выбор пакета сервера (nginx || apache)
    requestDoIt # Выбор что нужно сделать (Создать сайт || Редактировать сайт)
}
main