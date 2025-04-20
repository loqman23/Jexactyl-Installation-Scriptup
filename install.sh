Here's the complete file content with the updated header while maintaining all other functionality:

#!/bin/bash

# Jexactyl Installation & Upgrade Script
# Copyright © 2024 loqmanas
# https://github.com/loqman23

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Output functions
output() {
    echo -e "${BLUE}$1${NC}"
}

warn() {
    echo -e "${RED}$1${NC}"
}

success() {
    echo -e "${GREEN}$1${NC}"
}

# Version variables
PANEL="latest"
WINGS="latest"

# Function to check if script is running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        warn "Please run as root (use sudo)."
        exit 3
    fi
}

# Function to generate a random password
generate_password() {
    < /dev/urandom tr -dc 'a-zA-Z0-9' | head -c32 || true
}

# Function for MariaDB root password reset
mariadb_root_reset() {
    if ! command -v mysql &> /dev/null; then
        warn "MySQL/MariaDB is not installed. Installing it first..."
        if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
            apt-get update
            apt-get install -y mariadb-server
        elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
            dnf -y install mariadb-server
            systemctl enable --now mariadb
        fi
    fi
    
    rootpassword=$(generate_password)
    Q0="SET old_passwords=0;"
    Q1="SET PASSWORD FOR root@localhost = PASSWORD('$rootpassword');"
    Q2="FLUSH PRIVILEGES;"
    SQL="${Q0}${Q1}${Q2}"
    
    mysql -e "$SQL" || {
        warn "Failed to execute MySQL commands. Please check if MariaDB is running."
        exit 1
    }
    
    success "Your MariaDB root password is: $rootpassword"
    echo "$rootpassword" > /root/.mariadb_root
    chmod 600 /root/.mariadb_root
    success "Password also saved to /root/.mariadb_root"
}

# Preflight checks
preflight() {
    output "Jexactyl Installation & Upgrade Script"
    output "-----------------------------------"
    output ""

    check_root

    output "Please note that this script is meant to be installed on a fresh OS."
    output "Installing it on a non-fresh OS may cause problems."
    output ""
    output "Automatic operating system detection initialized..."

    os_check

    output "Automatic architecture detection initialized..."
    MACHINE_TYPE=$(uname -m)
    if [ "${MACHINE_TYPE}" == 'x86_64' ]; then
        output "64-bit server detected! Good to go."
        output ""
    else
        warn "Unsupported architecture detected! Please switch to 64-bit (x86_64)."
        exit 4
    fi

    output "Checking for virtualization..."
    # Install virtualization detection tools if not present
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        apt-get update --fix-missing -qq
        apt-get -y install -qq software-properties-common
        if [ "$lsb_dist" = "ubuntu" ]; then
            add-apt-repository -y universe
        fi
        apt-get -y install -qq virt-what curl
    elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        dnf -y install virt-what curl wget
    fi

    virt_serv=$(virt-what 2>/dev/null)
    
    if [ -z "$virt_serv" ]; then
        output "Virtualization: Bare Metal detected."
    elif [ "$virt_serv" = "openvz lxc" ]; then
        output "Virtualization: OpenVZ 7 detected."
    elif [ "$virt_serv" = "xen xen-hvm" ]; then
        output "Virtualization: Xen-HVM detected."
    elif [ "$virt_serv" = "xen xen-hvm aws" ]; then
        output "Virtualization: Xen-HVM on AWS detected."
        warn "When creating allocations for this node, please use the internal IP as AWS uses NAT routing."
        warn "Resuming in 5 seconds..."
        sleep 5
    else
        output "Virtualization: $virt_serv detected."
    fi
    
    output ""
    
    if [ -n "$virt_serv" ] && [ "$virt_serv" != "kvm" ] && [ "$virt_serv" != "vmware" ] && [ "$virt_serv" != "hyperv" ] && [ "$virt_serv" != "openvz lxc" ] && [ "$virt_serv" != "xen xen-hvm" ] && [ "$virt_serv" != "xen xen-hvm aws" ]; then
        warn "Unsupported type of virtualization detected. Please consult with your hosting provider whether your server can run Docker or not. Proceed at your own risk."
        warn "No support would be given if your server breaks at any point in the future."
        warn "Proceed? [y/N]"
        read -r choice
        case $choice in
            [Yy]*)  output "Proceeding..."
                    ;;
            *)      output "Cancelling installation..."
                    exit 5
                    ;;
        esac
        output ""
    fi

    output "Checking kernel compatibility..."
    if uname -r | grep -q xxxx; then
        warn "OVH kernel detected. This script will not work."
        warn "Please reinstall your server using a generic/distribution kernel."
        exit 6
    elif uname -r | grep -q pve; then
        warn "Proxmox LXE kernel detected. You have chosen to continue, proceeding at your own risk."
    elif uname -r | grep -q stab; then
        if uname -r | grep -q 2.6; then
            warn "OpenVZ 6 detected. This server will definitely not work with Docker. Exiting."
            exit 6
        fi
    elif uname -r | grep -q gcp; then
        output "Google Cloud Platform detected."
        warn "Please make sure you have a static IP setup, otherwise the system will not work after a reboot."
        warn "Please also make sure the GCP firewall allows the ports needed for the server to function normally."
        warn "When creating allocations for this node, please use the internal IP as Google Cloud uses NAT routing."
        warn "Resuming in 5 seconds..."
        sleep 5
    else
        output "Kernel check passed. Moving forward..."
        output ""
    fi
}

# Operating system check
os_check() {
    if [ -r /etc/os-release ]; then
        . /etc/os-release
        lsb_dist="$ID"
        dist_version="$VERSION_ID"
        if [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
            dist_version="$(echo $dist_version | awk -F. '{print $1}')"
        fi
    else
        warn "Cannot detect OS. Please install on a supported OS."
        exit 1
    fi
    
    if [ "$lsb_dist" = "ubuntu" ]; then
        if [ "$dist_version" != "20.04" ] && [ "$dist_version" != "22.04" ]; then
            warn "Unsupported Ubuntu version. Only Ubuntu 20.04 and 22.04 are supported."
            exit 2
        fi
        output "Detected: Ubuntu $dist_version"
    elif [ "$lsb_dist" = "debian" ]; then
        if [ "$dist_version" != "11" ]; then
            warn "Unsupported Debian version. Only Debian 11 is supported."
            exit 2
        fi
        output "Detected: Debian $dist_version"
    elif [ "$lsb_dist" = "fedora" ]; then
        if [ "$dist_version" != "35" ]; then
            warn "Unsupported Fedora version. Only Fedora 35 is supported."
            exit 2
        fi
        output "Detected: Fedora $dist_version"
    elif [ "$lsb_dist" = "centos" ]; then
        if [ "$dist_version" != "8" ]; then
            warn "Unsupported CentOS version. Only CentOS Stream 8 is supported."
            exit 2
        fi
        output "Detected: CentOS $dist_version"
    elif [ "$lsb_dist" = "rhel" ]; then
        if [ "$dist_version" != "8" ]; then
            warn "Unsupported RHEL version. Only RHEL 8 is supported."
            exit 2
        fi
        output "Detected: RHEL $dist_version"
    elif [ "$lsb_dist" = "rocky" ]; then
        if [ "$dist_version" != "8" ]; then
            warn "Unsupported Rocky Linux version. Only Rocky Linux 8 is supported."
            exit 2
        fi
        output "Detected: Rocky Linux $dist_version"
    elif [ "$lsb_dist" = "almalinux" ]; then
        if [ "$dist_version" != "8" ]; then
            warn "Unsupported AlmaLinux version. Only AlmaLinux 8 is supported."
            exit 2
        fi
        output "Detected: AlmaLinux $dist_version"
    else
        warn "Unsupported operating system."
        warn ""
        warn "Supported OS:"
        warn "Ubuntu: 20.04, 22.04"
        warn "Debian: 11"
        warn "Fedora: 35"
        warn "CentOS Stream: 8"
        warn "Rocky Linux: 8"
        warn "AlmaLinux: 8"
        warn "RHEL: 8"
        exit 2
    fi
}

# Installation options
install_options() {
    output "Please select your installation option:"
    output "[1] Install the panel ${PANEL}"
    output "[2] Install the wings ${WINGS}"
    output "[3] Install the panel ${PANEL} and wings ${WINGS}"
    output "[4] Upgrade panel to ${PANEL}"
    output "[5] Upgrade wings to ${WINGS}"
    output "[6] Upgrade panel to ${PANEL} and daemon to ${WINGS}"
    output "[7] Install phpMyAdmin (only use after panel installation)"
    output "[8] Emergency MariaDB root password reset"
    output "[9] Emergency database host information reset"
    read -r choice
    
    case $choice in
        1)  installoption=1
            output "You have selected ${PANEL} panel installation only."
            ;;
        2)  installoption=2
            output "You have selected wings ${WINGS} installation only."
            ;;
        3)  installoption=3
            output "You have selected ${PANEL} panel and wings ${WINGS} installation."
            ;;
        4)  installoption=4
            output "You have selected to upgrade the panel to ${PANEL}."
            ;;
        5)  installoption=5
            output "You have selected to upgrade the daemon to ${WINGS}."
            ;;
        6)  installoption=6
            output "You have selected to upgrade panel to ${PANEL} and daemon to ${WINGS}."
            ;;
        7)  installoption=7
            output "You have selected to install phpMyAdmin."
            ;;
        8)  installoption=8
            output "You have selected MariaDB root password reset."
            ;;
        9)  installoption=9
            output "You have selected Database Host information reset."
            ;;
        *)  warn "You did not enter a valid selection."
            install_options
            ;;
    esac
}

# User information collection
required_infos() {
    output "Please enter the desired admin email address:"
    read -r email
    
    # Validate email format
    if [[ ! $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        warn "Invalid email format. Please enter a valid email address."
        required_infos
        return
    fi
    
    dns_check
}

# DNS check
dns_check() {
    output "Please enter your FQDN (panel.domain.tld):"
    read -r FQDN

    # Validate domain format
    if [[ ! $FQDN =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](\.[a-zA-Z]{2,})+$ ]]; then
        warn "Invalid domain format. Please enter a valid domain (e.g., panel.example.com)."
        dns_check
        return
    fi

    output "Resolving DNS..."
    
    # Install dig if not present
    if ! command -v dig &> /dev/null; then
        if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
            apt-get update
            apt-get install -y dnsutils
        elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
            dnf -y install bind-utils
        fi
    fi
    
    SERVER_IP=$(dig +short myip.opendns.com @resolver1.opendns.com -4)
    DOMAIN_RECORD=$(dig +short "${FQDN}")
    
    if [ "${SERVER_IP}" != "${DOMAIN_RECORD}" ]; then
        warn ""
        warn "The entered domain does not resolve to the primary public IP of this server."
        warn "Please make an A record pointing to your server's IP. For example, if you make an A record called 'panel' pointing to your server's IP, your FQDN is panel.domain.tld"
        warn "If you are using Cloudflare, please disable the orange cloud (set to DNS only)."
        warn "If you do not have a domain, you can get a free one at https://freenom.com"
        
        output "Would you like to continue anyway? This is not recommended. [y/N]"
        read -r continue_dns
        
        if [[ "$continue_dns" =~ ^[Yy]$ ]]; then
            output "Continuing with unverified DNS..."
        else
            dns_check
            return
        fi
    else
        success "Domain resolved correctly. Good to go..."
    fi
}

# Setup repositories
repositories_setup() {
    output "Configuring repositories..."
    
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg sudo
        
        if [ "$lsb_dist" = "ubuntu" ]; then
            LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
            add-apt-repository -y ppa:redislabs/redis
            apt -y update
        elif [ "$lsb_dist" = "debian" ]; then
            apt-get -y install ca-certificates apt-transport-https dirmngr
            echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
            wget -qO- https://packages.sury.org/php/apt.gpg | apt-key add -
            apt-get -y update
        fi
        
        # Add MariaDB repository
        curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash
        
    elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        dnf -y install dnf-utils
        
        if [ "$lsb_dist" = "fedora" ]; then
            dnf -y install http://rpms.remirepo.net/fedora/remi-release-35.rpm
        else
            dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
            dnf -y install http://rpms.remirepo.net/enterprise/remi-release-8.rpm
        fi
    fi
    
    success "Repositories configured successfully."
}

# Install dependencies
install_dependencies() {
    output "Installing dependencies..."
    
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        # For Ubuntu 22.04, use PHP 8.1
        if [ "$dist_version" = "22.04" ]; then
            apt -y install php8.1 php8.1-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server
        else
            apt -y install php8.1 php8.1-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server
        fi
        
        # Install composer
        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
        
    elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        dnf -y module install nginx:mainline/common
        dnf -y module install php:remi-8.1/common
        dnf -y module install redis:remi-6.2/common
        dnf -y module install mariadb:10.5/server
        dnf -y install git policycoreutils-python-utils unzip wget jq php-mysql php-zip php-bcmath tar
        
        # Install composer
        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    fi
    
    success "Dependencies installed successfully."
}

# Install Jexactyl panel
install_jexactyl() {
    output "Creating database and setting up user..."
    
    # Start MariaDB if not running
    if ! systemctl is-active --quiet mariadb; then
        systemctl start mariadb
    fi
    
    if ! systemctl is-enabled --quiet mariadb; then
        systemctl enable mariadb
    fi
    
    password=$(generate_password)
    Q1="CREATE USER 'jexactyl'@'127.0.0.1' IDENTIFIED BY '$password';"
    Q2="CREATE DATABASE IF NOT EXISTS panel;"
    Q3="GRANT ALL PRIVILEGES ON panel.* TO 'jexactyl'@'127.0.0.1' WITH GRANT OPTION;"
    Q4="FLUSH PRIVILEGES;"
    
    SQL="${Q1}${Q2}${Q3}${Q4}"
    
    if ! mysql -e "$SQL"; then
        warn "Failed to create database. Check if MariaDB is running properly."
        exit 1
    fi
    
    output "Downloading Jexactyl..."
    mkdir -p /var/www/jexactyl
    cd /var/www/jexactyl || exit
    
    if [ "${PANEL}" = "latest" ]; then
        curl -Lo panel.tar.gz https://github.com/jexactyl/jexactyl/releases/latest/download/panel.tar.gz
    else
        curl -Lo panel.tar.gz https://github.com/jexactyl/jexactyl/releases/download/${PANEL}/panel.tar.gz
    fi
    
    tar -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    
    output "Installing Jexactyl..."
    cp .env.example .env
    
    # Generate application key
    php artisan key:generate --force
    
    # Install composer dependencies
    composer install --no-dev --optimize-autoloader --no-interaction
    
    # Setup environment
    php artisan p:environment:setup -n --author="$email" --url="https://$FQDN" --timezone=America/New_York --cache=redis --session=database --queue=redis --redis-host=127.0.0.1 --redis-pass="" --redis-port=6379
    php artisan p:environment:database --host=127.0.0.1 --port=3306 --database=panel --username=jexactyl --password="$password"
    
    # Run migrations and create admin user
    php artisan migrate --seed --force
    php artisan p:user:make --email="$email" --admin=1
    
    # Set proper ownership
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        chown -R www-data:www-data /var/www/jexactyl
    elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        chown -R nginx:nginx /var/www/jexactyl
        semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/jexactyl/storage(/.*)?"
        restorecon -R /var/www/jexactyl
    fi
    
    output "Setting up scheduled tasks..."
    (crontab -l 2>/dev/null; echo "* * * * * php /var/www/jexactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
    
    output "Setting up queue worker..."
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        cat > /etc/systemd/system/pteroq.service <<EOL
# Jexactyl Queue Worker File
# ----------------------------------

[Unit]
Description=Jexactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/jexactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOL
    elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        cat > /etc/systemd/system/pteroq.service <<EOL
# Jexactyl Queue Worker File
# ----------------------------------

[Unit]
Description=Jexactyl Queue Worker
After=redis-server.service

[Service]
User=nginx
Group=nginx
Restart=always
ExecStart=/usr/bin/php /var/www/jexactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOL
        # SELinux settings
        setsebool -P httpd_can_network_connect 1
        setsebool -P httpd_execmem 1
        setsebool -P httpd_unified 1
    fi
    
    systemctl daemon-reload
    systemctl enable --now pteroq.service
    
    success "Jexactyl panel has been successfully installed!"
}

# Upgrade Jexactyl panel
upgrade_jexactyl() {
    cd /var/www/jexactyl || {
        warn "Jexactyl installation directory not found. Is it installed?"
        exit 1
    }
    
    output "Upgrading Jexactyl panel..."
    
    # Backup current panel
    output "Creating backup of current panel..."
    mkdir -p /var/backup/jexactyl
    tar -czf "/var/backup/jexactyl/panel_backup_$(date +%Y%m%d%H%M%S).tar.gz" /var/www/jexactyl
    
    # Upgrade the panel
    php artisan p:upgrade || {
        warn "Panel upgrade failed. Please check the logs for more information."
        exit 1
    }
    
    # Set proper ownership
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        chown -R www-data:www-data /var/www/jexactyl
    elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        chown -R nginx:nginx /var/www/jexactyl
        restorecon -R /var/www/jexactyl
    fi
    
    success "Your panel has successfully been updated to version ${PANEL}"
}

# Configure NGINX for Ubuntu/Debian
nginx_config() {
    output "Configuring NGINX web server..."
    
    rm -rf /etc/nginx/sites-enabled/default
    
    # Determine PHP-FPM socket path based on distribution
    if [ "$dist_version" = "22.04" ]; then
        PHP_SOCKET="/run/php/php8.1-fpm.sock"
    else
        PHP_SOCKET="/run/php/php8.1-fpm.sock"
    fi
    
    # Create NGINX configuration
    cat > /etc/nginx/sites-available/jexactyl.conf <<EOL
server {
    listen 80;
    server_name ${FQDN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${FQDN};

    root /var/www/jexactyl/public;
    index index.php;

    access_log /var/log/nginx/jexactyl.app-access.log;
    error_log  /var/log/nginx/jexactyl.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/${FQDN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${FQDN}/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_prefer_server_ciphers on;

    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:${PHP_SOCKET};
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL
    
    ln -sf /etc/nginx/sites-available/jexactyl.conf /etc/nginx/sites-enabled/jexactyl.conf
    
    systemctl restart nginx
    success "NGINX configured successfully."
}

# Configure NGINX for RedHat-based systems
nginx_config_redhat() {
    output "Configuring NGINX web server..."
    
    # Determine PHP-FPM socket path for RHEL-based distros
    PHP_SOCKET="/var/run/php-fpm/php-fpm.sock"
    
    # Create NGINX configuration
    cat > /etc/nginx/conf.d/jexactyl.conf <<EOL
server {
    listen 80;
    server_name ${FQDN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${FQDN};

    root /var/www/jexactyl/public;
    index index.php;

    access_log /var/log/nginx/jexactyl.app-access.log;
    error_log  /var/log/nginx/jexactyl.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/${FQDN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${FQDN}/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_prefer_server_ciphers on;

    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:${PHP_SOCKET};
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL
    
    systemctl restart nginx
    chown -R nginx:nginx /var/www/jexactyl
    
    if [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        restorecon -R /var/www/jexactyl
    fi
    
    success "NGINX configured successfully."
}

# Configure PHP for RedHat-based systems
php_config() {
    output "Configuring PHP-FPM..."
    
    cat > /etc/php-fpm.d/www-jexactyl.conf <<EOL
[jexactyl]
user = nginx
group = nginx
listen = /var/run/php-fpm/jexactyl.sock
listen.owner = nginx
listen.group = nginx
listen.mode = 0750
pm = ondemand
pm.max_children = 9
pm.process_idle_timeout = 10s
pm.max_requests = 200
EOL
    
    systemctl restart php-fpm
    success "PHP-FPM configured successfully."
}

# Web server configuration based on distribution
webserver_config() {
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        nginx_config
    elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        php_config
        nginx_config_redhat
        chown -R nginx:nginx /var/lib/php/session
    fi
}

# Setup Jexactyl complete installation
setup_jexactyl() {
    install_dependencies
    install_jexactyl
    ssl_certs
    webserver_config
}

# Install Jexactyl Wings
install_wings() {
    cd /root || exit
    output "Installing Jexactyl Wings dependencies..."
    
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        apt-get -y install curl tar unzip
    elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        dnf -y install curl tar unzip
    fi
    
    output "Installing Docker..."
    if [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        dnf -y install docker-ce --allowerasing
    else
        curl -sSL https://get.docker.com/ | CHANNEL=stable bash
    fi
    
    systemctl enable --now docker
    
    output "Installing Jexactyl Wings..."
    mkdir -p /etc/pterodactyl
    cd /etc/pterodactyl || exit
    
    if [ "${WINGS}" = "latest" ]; then
        curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
    else
        curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/download/${WINGS}/wings_linux_amd64
    fi
    
    chmod u+x /usr/local/bin/wings
    
    cat > /etc/systemd/system/wings.service <<EOL
[Unit]
Description=Jexactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOL
    
    systemctl enable wings
    
    success "Wings ${WINGS} has been installed on your system."
    output "You should go to your panel and configure the node now."
    output "After configuration, run 'systemctl start wings' to start the Wings daemon."
    
    if [ "$lsb_dist" != "ubuntu" ] && [ "$lsb_dist" != "debian" ]; then
        output "------------------------------------------------------------------"
        warn "IMPORTANT NOTICE!"
        output "Since you are on a system with SELinux, you should change the Daemon Server File Directory"
        output "from /var/lib/jexactyl/volumes to /var/srv/containers/jexactyl in your node configuration."
        output "------------------------------------------------------------------"
    fi
}

# Upgrade Wings
upgrade_wings() {
    output "Upgrading Wings..."
    
    if [ "${WINGS}" = "latest" ]; then
        curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
    else
        curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/download/${WINGS}/wings_linux_amd64
    fi
    
    chmod u+x /usr/local/bin/wings
    systemctl restart wings
    
    success "Your Wings daemon has been updated to version ${WINGS}."
}

# Install phpMyAdmin
install_phpmyadmin() {
    output "Installing phpMyAdmin..."
    
    if [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        dnf -y install phpmyadmin
        ln -sf /usr/share/phpMyAdmin /var/www/jexactyl/public/phpmyadmin
    else
        apt -y install phpmyadmin
        ln -sf /usr/share/phpmyadmin /var/www/jexactyl/public/phpmyadmin
    fi
    
    cd /var/www/jexactyl/public/phpmyadmin || exit
    SERVER_IP=$(dig +short myip.opendns.com @resolver1.opendns.com -4)
    BOWFISH=$(generate_password)
    
    # Configure phpMyAdmin based on the distribution
    if [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        cat > /etc/phpMyAdmin/config.inc.php <<EOL
<?php
/* Servers configuration */
\$i = 0;
/* Server: MariaDB [1] */
\$i++;
\$cfg['Servers'][\$i]['verbose'] = 'MariaDB';
\$cfg['Servers'][\$i]['host'] = '${SERVER_IP}';
\$cfg['Servers'][\$i]['port'] = '3306';
\$cfg['Servers'][\$i]['socket'] = '';
\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['user'] = 'root';
\$cfg['Servers'][\$i]['password'] = '';
\$cfg['Servers'][\$i]['ssl'] = true;  
\$cfg['ForceSSL'] = true;
/* End of servers configuration */
\$cfg['blowfish_secret'] = '${BOWFISH}';
\$cfg['DefaultLang'] = 'en';
\$cfg['ServerDefault'] = 1;
\$cfg['UploadDir'] = '/var/lib/phpMyAdmin/upload';
\$cfg['SaveDir'] = '/var/lib/phpMyAdmin/save';
\$cfg['CaptchaLoginPublicKey'] = '6LcJcjwUAAAAAO_Xqjrtj9wWufUpYRnK6BW8lnfn';
\$cfg['CaptchaLoginPrivateKey'] = '6LcJcjwUAAAAALOcDJqAEYKTDhwELCkzUkNDQ0J5';
\$cfg['AuthLog'] = syslog
?>
EOL
        chmod 755 /etc/phpMyAdmin
        chmod 644 /etc/phpMyAdmin/config.inc.php
        chown -R nginx:nginx /var/www/jexactyl
        chown -R nginx:nginx /var/lib/phpMyAdmin/temp
    elif [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        cat > /etc/phpmyadmin/config.inc.php <<EOL
<?php
/* Servers configuration */
\$i = 0;
/* Server: MariaDB [1] */
\$i++;
\$cfg['Servers'][\$i]['verbose'] = 'MariaDB';
\$cfg['Servers'][\$i]['host'] = '${SERVER_IP}';
\$cfg['Servers'][\$i]['port'] = '3306';
\$cfg['Servers'][\$i]['socket'] = '';
\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['user'] = 'root';
\$cfg['Servers'][\$i]['password'] = '';
\$cfg['Servers'][\$i]['ssl'] = true;  
\$cfg['ForceSSL'] = true;
/* End of servers configuration */
\$cfg['blowfish_secret'] = '${BOWFISH}';
\$cfg['DefaultLang'] = 'en';
\$cfg['ServerDefault'] = 1;
\$cfg['UploadDir'] = '/var/lib/phpmyadmin/upload';
\$cfg['SaveDir'] = '/var/lib/phpmyadmin/save';
\$cfg['CaptchaLoginPublicKey'] = '6LcJcjwUAAAAAO_Xqjrtj9wWufUpYRnK6BW8lnfn';
\$cfg['CaptchaLoginPrivateKey'] = '6LcJcjwUAAAAALOcDJqAEYKTDhwELCkzUkNDQ0J5';
\$cfg['AuthLog'] = syslog
?>
EOL
        chmod 755 /etc/phpmyadmin
        chmod 644 /etc/phpmyadmin/config.inc.php
        chown -R www-data:www-data /var/www/jexactyl
        chown -R www-data:www-data /var/lib/phpmyadmin/temp
    fi
    
    # Configure Fail2Ban for phpMyAdmin
    if ! command -v fail2ban-client &> /dev/null; then
        if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
            apt -y install fail2ban
        elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
            dnf -y install fail2ban
        fi
    fi
    
    cat > /etc/fail2ban/jail.local <<EOL
[DEFAULT]
# Ban hosts for one hour:
bantime = 3600
# Override /etc/fail2ban/jail.d/00-firewalld.conf:
banaction = iptables-multiport
[sshd]
enabled = true
[phpmyadmin-syslog]
enabled = true
maxentry = 15
EOL
    systemctl restart fail2ban
    
    success "phpMyAdmin installed successfully."
}

# SSL certificate setup
ssl_certs() {
    output "Installing Let's Encrypt and creating SSL certificate..."
    
    # Install Certbot
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        apt-get -y install certbot
    elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        dnf -y install certbot
    fi
    
    # Get SSL certificate based on installation option
    if [ "$installoption" = "1" ] || [ "$installoption" = "3" ]; then
        if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
            apt-get -y install python3-certbot-nginx
        elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
            dnf -y install python3-certbot-nginx
        fi
        
        certbot --nginx --redirect --no-eff-email --email "$email" --agree-tos -d "$FQDN"
        setfacl -Rdm u:mysql:rx /etc/letsencrypt
        setfacl -Rm u:mysql:rx /etc/letsencrypt
        systemctl restart mariadb
    fi
    
    if [ "$installoption" = "2" ]; then
        certbot certonly --standalone --no-eff-email --email "$email" --agree-tos -d "$FQDN" --non-interactive
    fi
    
    systemctl enable --now certbot.timer
    success "SSL certificate obtained successfully."
}

# Firewall configuration
firewall() {
    output "Setting up Fail2Ban..."
    
    if ! command -v fail2ban-client &> /dev/null; then
        if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
            apt -y install fail2ban
        elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
            dnf -y install fail2ban
        fi
    fi
    
    systemctl enable fail2ban
    
    cat > /etc/fail2ban/jail.local <<EOL
[DEFAULT]
# Ban hosts for ten hours:
bantime = 36000
# Override /etc/fail2ban/jail.d/00-firewalld.conf:
banaction = iptables-multiport
[sshd]
enabled = true
EOL
    
    systemctl restart fail2ban
    
    output "Configuring firewall..."
    
    # Set up firewall based on distribution
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        apt-get -y install ufw
        ufw allow 22
        
        if [ "$installoption" = "1" ]; then
            ufw allow 80
            ufw allow 443
            ufw allow 3306
        elif [ "$installoption" = "2" ]; then
            ufw allow 80
            ufw allow 8080
            ufw allow 2022
        elif [ "$installoption" = "3" ]; then
            ufw allow 80
            ufw allow 443
            ufw allow 8080
            ufw allow 2022
            ufw allow 3306
        fi
        
        yes | ufw enable
        
    elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        dnf -y install firewalld
        systemctl enable firewalld
        systemctl start firewalld
        
        if [ "$installoption" = "1" ]; then
            firewall-cmd --add-service=http --permanent
            firewall-cmd --add-service=https --permanent
            firewall-cmd --add-service=mysql --permanent
        elif [ "$installoption" = "2" ]; then
            firewall-cmd --permanent --add-service=http
            firewall-cmd --permanent --add-port=2022/tcp
            firewall-cmd --permanent --add-port=8080/tcp
            firewall-cmd --permanent --zone=trusted --change-interface=jexactyl0
            firewall-cmd --zone=trusted --add-masquerade --permanent
        elif [ "$installoption" = "3" ]; then
            firewall-cmd --add-service=http --permanent
            firewall-cmd --add-service=https --permanent
            firewall-cmd --permanent --add-port=2022/tcp
            firewall-cmd --permanent --add-port=8080/tcp
            firewall-cmd --permanent --add-service=mysql
            firewall-cmd --permanent --zone=trusted --change-interface=jexactyl0
            firewall-cmd --zone=trusted --add-masquerade --permanent
        fi
        
        firewall-cmd --reload
    fi
    
    success "Firewall configured successfully."
}

# Linux system hardening
harden_linux() {
    output "Hardening Linux system..."
    
    # Configure kernel security settings
    echo "kernel.yama.ptrace_scope=3" > /etc/sysctl.d/30_security-misc.conf
    echo "kernel.kptr_restrict=2" >> /etc/sysctl.d/30_security-misc.conf
    echo "kernel.unprivileged_bpf_disabled=1" >> /etc/sysctl.d/30_security-misc.conf
    echo "net.core.bpf_jit_harden=2" >> /etc/sysctl.d/30_security-misc.conf
    echo "kernel.printk = 3 3 3 3" > /etc/sysctl.d/30_silent-kernel-printk.conf
    
    # Apply sysctl settings
    sysctl --system
    
    success "Linux system hardened successfully."
}

# Database host reset
database_host_reset() {
    output "Resetting database host information..."
    
    SERVER_IP=$(dig +short myip.opendns.com @resolver1.opendns.com -4)
    adminpassword=$(generate_password)
    
    Q0="SET old_passwords=0;"
    Q1="CREATE USER IF NOT EXISTS 'admin'@'$SERVER_IP' IDENTIFIED BY '$adminpassword';"
    Q2="GRANT ALL PRIVILEGES ON *.* TO 'admin'@'$SERVER_IP' WITH GRANT OPTION;"
    Q3="FLUSH PRIVILEGES;"
    
    SQL="${Q0}${Q1}${Q2}${Q3}"
    
    if ! mysql -e "$SQL"; then
        warn "Failed to reset database host information. Check if MariaDB is running properly."
        exit 1
    fi
    
    success "New database host information:"
    output "Host: $SERVER_IP"
    output "Port: 3306"
    output "User: admin"
    output "Password: $adminpassword"
    
    # Save credentials to a secure file
    echo "Host: $SERVER_IP" > /root/.db_credentials
    echo "Port: 3306" >> /root/.db_credentials
    echo "User: admin" >> /root/.db_credentials
    echo "Password: $adminpassword" >> /root/.db_credentials
    chmod 600 /root/.db_credentials
    
    output "Credentials also saved to /root/.db_credentials"
}

# Broadcast installation success message
broadcast() {
    output "------------------------------------------------------------------"
    success "Jexactyl Successfully Installed!"
    output ""
    output "Panel URL: https://$FQDN"
    output "Admin Email: $email"
    output "Note: All unnecessary ports are blocked by default."
    
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        output "Use 'ufw allow <port>' to enable your desired ports."
    elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        output "Use 'firewall-cmd --permanent --add-port=<port>/tcp' to enable your desired ports."
    fi
    
    output "------------------------------------------------------------------"
    output ""
}

# Broadcast wings installation success message
broadcast_wings() {
    output "------------------------------------------------------------------"
    success "Wings Successfully Installed!"
    output "Remember to add this node in your panel and then run:"
    output "  systemctl start wings"
    output "------------------------------------------------------------------"
    output ""
}

# Main execution
clear
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║                  JEXACTYL INSTALLATION SCRIPT                 ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Run preflight checks
preflight

# Show installation options
install_options

# Main installation flow
case $installoption in
    1)  repositories_setup
        required_infos
        firewall
        harden_linux
        setup_jexactyl
        broadcast
        ;;
    2)  repositories_setup
        required_infos
        firewall
        harden_linux
        ssl_certs
        install_wings
        broadcast_wings
        ;;
    3)  repositories_setup
        required_infos
        firewall
        harden_linux
        setup_jexactyl
        install_wings
        broadcast
        broadcast_wings
        ;;
    4)  upgrade_jexactyl
        ;;
    5)  upgrade_wings
        ;;
    6)  upgrade_jexactyl
        upgrade_wings
        ;;
    7)  install_phpmyadmin
        ;;
    8)  mariadb_root_reset
        ;;
    9)  database_host_reset
        ;;
esac

echo ""
echo "Thank you for using the Jexactyl installation script!"
echo "If you encounter any issues, please report them on the GitHub repository."
echo ""