#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NORMAL='\033[0m'
UNDERLINE='\033[4m'
F_NORMAL='\033[0m'

PATH_NGINX=("/etc/nginx/sites-available" "/etc/nginx/sites-enabled")
PATH_APACHE=("/etc/apache2/sites-available" "/etc/apache2/sites-enabled")
PATH_DIRECTORY="null" # Путь до директории где распологается сайт
SELECT_SITE="null" # Выбранный сайт в методе editSite

SELECT_SERVER="null"
SELECT_USER="null"
NAME_SITE="null"

tput sgr0 

# Функция проверяющая существует ли пользователь(его домашняя папка)
function checkUser {
    [ -d /home/$1 ] 
}

# Метод создающий конфигурационный файл apache || nginx
function createConfig {
    if [[ $SELECT_SERVER == "apache" ]]
    then
    
        export CONFIGAPACHE=$(cat <<END
<VirtualHost *:80>
    ServerName $NAME_SITE
    DocumentRoot $PATH_DIRECTORY

    <Directory $PATH_DIRECTORY>
        Options -Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /home/$SELECT_USER/logs/$NAME_SITE/error.log
    CustomLog /home/$SELECT_USER/logs/$NAME_SITE/error.log combined
</VirtualHost>
END
    );
    
        sudo echo "$CONFIGAPACHE" >> "${PATH_APACHE[0]}/$NAME_SITE.conf"
        sudo a2ensite "$NAME_SITE.conf"
    
    elif [[ $SELECT_SERVER == "nginx" ]]
    then
        echo -en "${RED}Поддержка создания конфигурационного файла для nginx в разработке${NORMAL}"
        # Добавить откат действий
        exit
    fi
}

function createSite {
    echo -en "\n${UNDERLINE}Укажите название сайта:${F_NORMAL}"
    read nameSites
    NAME_SITE=$nameSites

    # Подтверждение действия
    echo -en "\n${UNDERLINE}Название сайта $NAME_SITE, подтвердить?(y|n)${F_NORMAL}"
    read selectAccept
    if [[ $selectAccept == "n" ]]
    then
        createSite
    fi
    
    echo -en "\n${UNDERLINE}Создание директории сайта...${F_NORMAL}"
    PATH_DIRECTORY="/home/$SELECT_USER/sites/$NAME_SITE"
    mkdir /home/$SELECT_USER/sites/$NAME_SITE
    mkdir /home/$SELECT_USER/logs/$NAME_SITE
    sudo echo "<html><head><title>Test page</title></head><body>Page for check running site</body></html>" >> "/home/$SELECT_USER/sites/$NAME_SITE/index.html"
    sudo chmod -R 777 /home/$SELECT_USER/sites/$NAME_SITE
    sudo chmod -R 777 /home/$SELECT_USER/logs/$NAME_SITE
    echo -en "${GREEN}[OK]${NORMAL}\n"

    echo -en "${UNDERLINE}Создание конфигурационного файла...${F_NORMAL}"
    createConfig
    echo -en "${GREEN}[OK]${NORMAL}\n"

    # Перезагрузка сервиса
    if [[ $SELECT_SERVER == "apache" ]]
    then
        echo -en "${UNDERLINE}Перезагрузка сервиса...${F_NORMAL}"
        service apache2 restart
        echo -en "${GREEN}[OK]${NORMAL}\n"
    elif [[ $SELECT_SERVER == "nginx" ]]
    then
        echo -en "${RED}Поддержка создания конфигурационного файла для nginx в разработке${NORMAL}"
        # Добавить откат действий
        exit
    fi 
    echo -en "\n${UNDERLINE}Сайт успешно создан.\nДиректория сайта /home/$SELECT_USER/$NAME_SITE\nДиректория логов /home/$SELECT_USER/logs/$NAME_SITE\n ${F_NORMAL}"
}

# Удаление конфигураций
function removeConfiguration {
    # Проверка существования конфигурации
    if ! [ -f /etc/apache2/sites-available/$SELECT_SITE.conf ]
    then
        echo -en "\n${UNDERLINE}Файл конфигурации отсутствует...${F_NORMAL}"
    else
        sudo a2dissite $SELECT_SITE.conf
        sudo rm /etc/apache2/sites-available/$SELECT_SITE.conf
    fi
}

# Удаление директории
function removeDirectory {
    sudo rm -r /home/$SELECT_USER/sites/$SELECT_SITE
    sudo rm -r /home/$SELECT_USER/logs/$SELECT_SITE
}

function removeSite {
    removeConfiguration # Удаляем конфигурации
    removeDirectory # Удаляем директории
    sudo systemctl reload apache2
}

function editSite {
    if [[ $SELECT_SERVER == "nginx" ]]
    then
        echo -en "\n${UNDERLINE}${RED}Подддержка nginx пока не доступна в изменение сайта${NORMAL}${F_NORMAL}"
        exit
    fi

    echo -en "\n${UNDERLINE}Список ранее созданных сайтов:\n${F_NORMAL}"
    
    TEMP_COUNTER=1
    arrayfiles=()

    # Выводим список сайтов (директорий)
    for file in `find /home/$SELECT_USER/sites -maxdepth 1 | grep /home/$SELECT_USER/sites/[a-zA-Z0-9]`
    do
        echo -en "$TEMP_COUNTER. "
        TEMP_TEXT=`echo $file | sed 's/\/home\/[a-z]*\/sites\///g'`
        echo $TEMP_TEXT
        TEMP_COUNTER=$[TEMP_COUNTER +1]
        arrayfiles[${#arrayfiles[*]}]=$TEMP_TEXT
    done
    read selectCounter
    selectCounter=$[selectCounter -1]

    # Проверка существования директории
    if ! [ -d /home/$SELECT_USER/sites/${arrayfiles[$selectCounter]} ];
    then
        echo -en "${RED}ВНИМАНИЕ ДАННОЙ ДИРЕКТОРИИ НЕ СУЩЕСТВУЕТ${NORMAL}"
        editSite
    fi
    
    # Подтверждение выбора
    echo -en "\n${UNDERLINE}Выбран ${arrayfiles[$selectCounter]}, подтвердить?(y|n)${F_NORMAL}"
    read selectAccept

    if [[ $selectAccept == "n" ]]
    then
        editSite;
    fi

    # Запись в глобальную переменную
    SELECT_SITE=${arrayfiles[$selectCounter]}

    # Выберем действие уже с ранее выбранным сайтом
    echo -en "\n${UNDERLINE}Выберите действие:\n1.Удалить сайт и конфигурационный файл\n${F_NORMAL}"
    read selectAction

    case $selectAction in 
        1)
            removeSite;;
    esac
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

function main {
    requestSelectUser # Выбор пользователя
    requestSelectServer # Выбор пакета сервера (nginx || apache)
    requestDoIt # Выбор что нужно сделать (Создать сайт || Редактировать сайт)
}
main