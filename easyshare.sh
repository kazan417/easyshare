#!/bin/bash
###автор Казанцев Михаил Валеьевич (kazan417@mail.ru) лицензия MIT
echo "Это скрипт для настройки автоматического монтирования дисков"
echo "Диски подключаются только доменным пользователям использовать его после выполнения easyjoin иначе не сработает"
if [ -n "$(command -v yum)" ]; then
  if [[ $EUID -ne 0 ]]; then
	 echo "найден yum устанавливаем требуемые программы с помощью yum"
     echo "введите пароль суперпользователя"
     su -c 	"/bin/bash ./easyshare.sh"
     if [ -f "/etc/security/pam_mount.conf.xml" ]; then
       echo "автоматическое монтирование настроено"
       read
       exit 0
     else
       echo "Ошибка получения привелегированных прав доступа"
       read
     fi
     exit 1
  fi
     echo "найден yum устанавливаем требуемые программы с помощью yum"
     yum -y install cifs-utils pam_mount
     echo "Добавляем модуль автомонтирования в автозагрузку полсе входа пользователя"
     echo "session     optional                   pam_mount.so disable_interactive" >> /etc/pam.d/postlogin
     echo "Включаем poly polyinstantiation_enabled"
	 setsebool -P polyinstantiation_enabled 1
     semodule -X 300 -i my-gdmsessionwor.pp
fi
if [ -n "$(command -v apt-get)" ]; then
	echo "найден apt-get устанавливаем требуемые программы с помощью apt-get"
  if [[ $EUID -ne 0 ]]; then
     echo "введите пароль пользователся с правами sudo"
     sudo ./easyshare.sh
     if [ -f "/etc/security/pam_mount.conf.xml" ]; then
       echo "автоматическое монтирование настроено"
       read
       exit 0
     else
       echo "Ошибка получения привелегированных прав доступа"
       read
     fi
     exit 1
  fi
	apt-get -y install cifs-utils libpam-mount
    sed -i 's/session optional pam_mount.so/session optional pam_mount.so disable_interactive/' /etc/pam.d/common-session
fi
echo "введите имя сервера с данными нфпример server-data"
read servername
echo "введите имя общей папки например adm_share, возможно нужно добавить в конец $ если папка не отображается в сетевом окружении"
read sharename
echo "Записываем файл /etc/security/pam_mount.conf.xml"
cat << EOF > /etc/security/pam_mount.conf.xml
<?xml
version="1.0" encoding="utf-8" ?>
<!DOCTYPE pam_mount SYSTEM "pam_mount.conf.xml.dtd">
<!-- See pam_mount.conf(5) for a description. -->
<pam_mount>
<!--
debug should come before everything else,
since this file is still processed in 
a single pass from top-to-bottom -->
<debug enable="0" />
<!--
Volume definitions -->
<logout wait="50000" hup="1" term="1" kill="1" />
<cifsmount>mount.cifs //%(SERVER)/%(VOLUME) %(MNTPT)
-o %(OPTIONS) </cifsmount>
<!--
pam_mount parameters: General tunables -->
<!-- Описание тома, который должен монтироваться -->
<volume
sgrp="Domain Users"
fstype="cifs" server="$servername" path="$sharename"
mountpoint="~/S" 
options="uid=%(USERUID),user=%(USER),rw,setuids,perm,soft,sec=krb5,cruid=%(USERUID),iocharset=utf8"/><!-- <luserconf name=".pam_mount.conf.xml" /> -->

<volume
sgrp="domain users"
fstype="cifs" server="$servername" path="$sharename"
mountpoint="~/S" 
options="uid=%(USERUID),user=%(USER),rw,setuids,perm,soft,sec=krb5,cruid=%(USERUID),iocharset=utf8"/><!-- <luserconf name=".pam_mount.conf.xml" /> -->

<volume
sgrp="domain users@mgkb.ru"
fstype="cifs" server="$servername" path="$sharename"
mountpoint="~/S" 
options="uid=%(USERUID),user=%(USER),rw,setuids,perm,soft,sec=krb5,cruid=%(USERUID),iocharset=utf8"/><!-- <luserconf name=".pam_mount.conf.xml" /> -->

<!-- Note that commenting out mntoptions will give you
the defaults.
You will need to explicitly
initialize it with the empty string
to reset the defaults to
nothing. -->

<mntoptions allow="nosuid,nodev,loop,encryption,fsck,nonempty,allow_root,allow_other" />

<!--

<mntoptions deny="suid,dev" />

<mntoptions allow="*" />

<mntoptions deny="*" />

-->

<mntoptions require="nosuid,nodev" />

<logout wait="0" hup="no" term="no" kill="no" />

<!-- pam_mount parameters: Volume-related -->

<mkmountpoint enable="1" remove="true" />

</pam_mount>
EOF

echo "все выполнено успешно. Нажмите любую клавишу..."
read
