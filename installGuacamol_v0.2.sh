#!/bin/bash

# Nom		    : install désinstall guacamole
# Description	: permet d'installer et désinstaller wireguard en fonction des paramètres
# Param 1	    : -i    installer guacamole
# Param 2	    : -d    désinstaller guacamole / clean la conf
# Auteur	    : Matteo MARTINI Thomas LE VOT Margaux TELA


function printHelp() {
    echo "USAGE :             ./install_Guacamole.sh [-h] [-i] [-c]"
    echo "Param :  -h          Print ce message d'aide"
    echo "Param :  -i          installer et configurer guacamole"
    echo "Param :  -d          clean la conf existante de guacamole"
}

function install_guacamole(){ 
        apt install sudo tree mc vim rsync net-tools mlocate htop screen -y

    wget https://github.com/cheat/cheat/releases/download/4.2.3/cheat-linux-amd64.gz
    gunzip cheat-linux-amd64.gz
    chmod a+x cheat-linux-amd64
    mv -v cheat-linux-amd64 /usr/local/bin/cheat

    apt install git -y
    mkdir -pv /opt/COMMUN/cheat/cheatsheets/community
    mkdir -v /opt/COMMUN/cheat/cheatsheets/personal
    cheat --init > /opt/COMMUN/cheat/conf.yml
    sed -i 's;/root/.config/; /opt/COMMUN/;' /opt/COMMUN/cheat/conf.yml
    git clone https://github.com/cheat/cheatsheets.git
    mv -v cheatsheets/[a-z]* /opt/COMMUN/cheat/cheatsheets/community

    groupadd -g 10000 commun 
    chgrp -Rv commun /opt/COMMUN/
    chmod 2770 /opt/COMMUN/cheat/cheatsheets/personal
    #find /opt/COMMUN/cheat/cheatsheets/personal -type d -exec chmod 2770 {} \;
    #find /opt/COMMUN/ -type f -exec chmod 660 {} \;

    useradd -m -G 10000 -s /bin/bash esgi
    echo -e 'esgi\nesgi' | sudo passwd esgi
    usermod -aG sudo esgi
    usermod -aG commun esgi
    echo "umask 007 " >> /home/esgi/.bashrc
    mkdir -v /home/esgi/.config 
    ln -s /opt/COMMUN/cheat /home/esgi/.config/cheat 
    chown -R esgi /home/esgi/.config
    useradd -m -G 10000 -s /bin/bash davy
    echo -e 'davy\ndavy' | sudo passwd davy
    usermod -aG sudo davy
    usermod -aG commun davy
    echo "umask 007 " >> /home/davy/.bashrc
    mkdir -v /home/davy/.config
    ln -s /opt/COMMUN/cheat /home/davy/.config/cheat 
    chown -R davy /home/davy/.config

    mkdir -v /root/.config
    ln -s /opt/COMMUN/cheat /root/.config/cheat
    mkdir /etc/skel/.config/
    ln -s /opt/COMMUN/cheat /etc/skel/.config/cheat
    echo "umask 007" >> /etc/skel/.bashrc
    cat >> /root/.bashrc << EOF
    alias ll="ls -rtl"
    alias grep="grep --color"
    alias rm="rm -vi --preserve-root"
    alias chown="chown -v --preserve-root"
    alias chmod="chmod -v --preserve-root"
    alias chgrp="chgrp -v --preserve-root"
EOF
    # Dependencies
    sudo apt install -y freerdp2-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libcairo2-dev libjpeg62-turbo-dev libjpeg-dev libpng-dev libtool-bin libpango1.0-dev libpango1.0-0 libssh2-1 libwebsockets16 libwebsocketpp-dev libossp-uuid-dev libssl-dev libwebp-dev libvorbis-dev libpulse-dev libwebsockets-dev libvncserver-dev libssh2-1-dev openssl

    # TomCat
    sudo apt install -y tomcat9 tomcat9-admin tomcat9-common tomcat9-user

    # Activate TomCat
    sudo systemctl enable --now tomcat9

    # Verif TomCat status
    #sudo systemctl status tomcat9

    # Compilation du serveur Guacamole
    cd /usr/src

    # Downlaod latest version of guacamol server
    sudo wget https://dlcdn.apache.org/guacamole/1.3.0/source/guacamole-server-1.3.0.tar.gz

    # Unzip
    sudo tar -xf guacamole-server-1.3.0.tar.gz
    cd guacamole-server-1.3.0

    # Check config 
    sudo ./configure --with-systemd-dir=/etc/systemd/system/ --disable-dependency-tracking

    # Compile Guacamol server 
    sudo apt install make
    sudo make
    sudo make install

    # Apply config to system
    sudo ldconfig

    # Config Guagacmole server
    sudo mkdir -p /etc/guacamole/{extensions,lib}
    sudo echo 'GUACAMOLE_HOME=/etc/guacamole' >> /etc/default/tomcat9

    # Create guacamole.properties file
    sudo echo -e "# Hostname and port of guacamole proxy\n
    guacd-hostname: localhost\n
    guacd-port:	4822\n
    user-mapping:    /etc/guacamole/user-mapping.xml" > /etc/guacamole/guacamole.properties

    # Past config :
    #""
    # Hostname and port of guacamole proxy
    #guacd-hostname: localhost
    #guacd-port:     4822
    # user mapping and user connections
    #user-mapping:    /etc/guacamole/user-mapping.xml
    #""

    sudo echo -e "<user-mapping>

        <!-- Per-user authentication and config information -->

        <!-- A user using md5 to hash the password
            guacadmin user and its md5 hashed password below is used to 
                login to Guacamole Web UI-->
        <authorize
                    username='guacadmin'
                    password='5f4dcc3b5aa765d61d8327deb882cf99'
                    encoding='md5'>

            <!-- First authorized Remote connection -->
            <connection name='Debian 11 BOOKSTACK'>
                <protocol>ssh</protocol>
                <param name='hostname'>10.33.2.246</param>
                <param name='port'>22</param>
            </connection>

            <!-- Second authorized remote connection -->
            <connection name='Windows 10 RDP HOME'>
                <protocol>rdp</protocol>
                <param name='hostname'>10.33.4.198</param>
                <param name='username'>totaota</param>
            <param name='port'>3389</param>
            <param name="security">nla</param>
                <param name='ignore-cert'>true</param>
            </connection>

        </authorize>
    </user-mapping>" > /etc/guacamole/user-mapping.xml

    # Generate SSL Certificat (Optional)

    #openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/guacamole-selfsigned.key -out /etc/ssl/certs/guacamole-selfsigned.crt

    ## Add user to allow RDP connection
    sudo useradd -M -d /var/lib/guacd/ -r -s /sbin/nologin -c "Guacd User" guacd
    sudo mkdir /var/lib/guacd
    sudo chown -R guacd: /var/lib/guacd
    sudo sed -i 's/daemon/guacd/' /etc/systemd/system/guacd.service

    #systemctl enable --now guacd
    systemctl daemon-reload
    systemctl restart tomcat9 guacd
    systemctl status guacd

}

function delete_guacamole(){
    # dependencies
    apt-get purge --autoremove -y freerdp2-dev libavcodec-dev libavformat-dev \
    libavutil-dev libswscale-dev libcairo2-dev libjpeg62-turbo-dev libjpeg-dev \
    libpng-dev libtool-bin libpango1.0-dev libpango1.0-0 libssh2-1 libwebsockets16 \
    libwebsocketpp-dev libossp-uuid-dev libssl-dev libwebp-dev libvorbis-dev \
    libpulse-dev libwebsockets-dev libvncserver-dev libssh2-1-dev openssl

    # conf files
    rm -f /etc/guacamole/user-mapping.xml /etc/guacamole/guacamole.properties
    
    # tomcat PKGs
    apt-get purge --autoremove -y tomcat9 tomcat9-admin tomcat9-common tomcat9-user

}

if [ $# = 0 ] || [ $1 = "-h" ]; then
    printHelp

elif [ $1 = "-i" ]; then
    install_guacamole

elif [ $1 = "-d" ]; then
    delete_guacamole
fi