#!/bin/bash

# Jexactyl Custom Theme Installer
# Copyright © 2024 Loqman AS
# Website: https://loqman.netlify.app
# GitHub: https://github.com/loqman23

# Color codes
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Output functions
output() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${RED}[WARNING]${NC} $1"
}

# Show logo
show_logo() {
    echo -e "${PURPLE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║               JEXACTYL THEME CUSTOMIZER                       ║"
    echo "║                     By Loqman AS © 2024                       ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Detect OS distribution for setting proper permissions
detect_distro() {
    if command -v lsb_release >/dev/null 2>&1; then
        lsb_dist="$(lsb_release -is | tr '[:upper:]' '[:lower:]')"
    elif [ -f /etc/os-release ]; then
        lsb_dist="$(. /etc/os-release && echo "$ID" | tr '[:upper:]' '[:lower:]')"
    fi
    
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        WEB_USER="www-data"
    elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        WEB_USER="nginx"
    else
        # Default to www-data if can't determine
        WEB_USER="www-data"
    fi
}

# Theme customization confirmation
confirm_theme_customization() {
    echo -e "${YELLOW}"
    echo "Would you like to install the custom theme for Jexactyl? [y/N]"
    echo -e "${NC}"
    read -r choice
    case $choice in
        [Yy]*)  customize_theme ;;
        *)      output "Skipping theme customization." ;;
    esac
}

# Theme customization function
customize_theme() {
    output "Installing custom theme for Jexactyl..."
    
    # Navigate to Jexactyl directory
    cd /var/www/jexactyl || { warn "Jexactyl directory not found!"; exit 1; }
    
    # Backup original theme files
    output "Creating backup of original theme files..."
    TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    mkdir -p backup/themes-$TIMESTAMP
    
    if [ -d "public/themes" ]; then
        cp -r public/themes backup/themes-$TIMESTAMP/
    fi
    
    # Create custom theme directory
    output "Creating custom theme directory..."
    mkdir -p public/themes/custom/css
    
    # Create the custom CSS file
    output "Creating custom theme CSS file..."
    cat > public/themes/custom/css/custom.css <<EOL
:root {
    --primary: #8960DC;
    --primary-light: #9D7DE5;
    --primary-dark: #4B248E;
    --secondary: #5B5B5B;
    --background: #000000;
    --background-light: #1A1A1A;
    --background-card: rgba(20, 20, 20, 0.8);
}

/* Global Styles */
body {
    background: var(--background);
    color: #ffffff;
    font-family: 'Montserrat', sans-serif;
}

/* Navigation */
.navbar {
    background: var(--background-card);
    border-bottom: 1px solid var(--primary);
    box-shadow: 0 2px 10px rgba(137, 96, 220, 0.1);
}

.navbar-brand {
    color: var(--primary) !important;
}

.navbar-nav > li > a {
    color: #ffffff !important;
    transition: color 0.2s;
}

.navbar-nav > li > a:hover {
    color: var(--primary) !important;
}

/* Buttons */
.btn-primary {
    background: var(--primary);
    border-color: var(--primary-dark);
    transition: all 0.2s;
}

.btn-primary:hover {
    background: var(--primary-dark);
    border-color: var(--primary);
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(137, 96, 220, 0.2);
}

/* Cards and Panels */
.panel {
    background: var(--background-card);
    border: 1px solid var(--primary);
    border-radius: 8px;
    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
}

.panel-heading {
    background: var(--primary);
    color: #ffffff;
    border-radius: 7px 7px 0 0;
}

/* Forms */
.form-control {
    background: var(--background-light);
    border: 1px solid var(--primary);
    color: #ffffff;
    transition: all 0.2s;
}

.form-control:focus {
    border-color: var(--primary-light);
    box-shadow: 0 0 0 0.2rem rgba(137, 96, 220, 0.25);
}

/* Tables */
.table {
    background: var(--background-card);
    color: #ffffff;
}

.table > thead > tr > th {
    border-bottom: 2px solid var(--primary);
    color: var(--primary);
}

.table > tbody > tr > td {
    border-top: 1px solid rgba(137, 96, 220, 0.1);
}

/* Sidebar */
.sidebar {
    background: var(--background-card);
    border-right: 1px solid var(--primary);
}

.sidebar-menu > li > a {
    color: #ffffff;
    transition: all 0.2s;
}

.sidebar-menu > li > a:hover {
    background: var(--primary);
    color: #ffffff;
}

/* Console */
.terminal {
    background: var(--background);
    border: 1px solid var(--primary);
    border-radius: 8px;
    font-family: 'Fira Code', monospace;
}

/* Alerts */
.alert {
    border-radius: 8px;
    border: none;
}

.alert-success {
    background: rgba(40, 167, 69, 0.2);
    border: 1px solid #28a745;
    color: #28a745;
}

.alert-danger {
    background: rgba(220, 53, 69, 0.2);
    border: 1px solid #dc3545;
    color: #dc3545;
}

/* Progress Bars */
.progress {
    background: var(--background-light);
    border-radius: 8px;
    overflow: hidden;
}

.progress-bar {
    background: var(--primary);
    transition: width 0.3s ease;
}

/* Modals */
.modal-content {
    background: var(--background-card);
    border: 1px solid var(--primary);
    border-radius: 12px;
}

.modal-header {
    border-bottom: 1px solid var(--primary);
}

.modal-footer {
    border-top: 1px solid var(--primary);
}

/* Tooltips */
.tooltip-inner {
    background: var(--primary);
    border-radius: 4px;
}

/* Animations */
@keyframes pulse {
    0% {
        box-shadow: 0 0 0 0 rgba(137, 96, 220, 0.4);
    }
    70% {
        box-shadow: 0 0 0 10px rgba(137, 96, 220, 0);
    }
    100% {
        box-shadow: 0 0 0 0 rgba(137, 96, 220, 0);
    }
}

/* Custom Components */
.status-indicator {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    display: inline-block;
    margin-right: 8px;
}

.status-indicator.online {
    background: #28a745;
    box-shadow: 0 0 8px rgba(40, 167, 69, 0.4);
}

.status-indicator.offline {
    background: #dc3545;
    box-shadow: 0 0 8px rgba(220, 53, 69, 0.4);
}

/* Server Cards */
.server-card {
    background: var(--background-card);
    border: 1px solid var(--primary);
    border-radius: 12px;
    padding: 20px;
    margin-bottom: 20px;
    transition: all 0.3s;
}

.server-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 8px 20px rgba(137, 96, 220, 0.2);
}

/* Statistics Widgets */
.stat-widget {
    background: linear-gradient(45deg, var(--primary-dark), var(--primary));
    border-radius: 12px;
    padding: 20px;
    color: #ffffff;
    text-align: center;
    transition: all 0.3s;
}

.stat-widget:hover {
    transform: scale(1.02);
}

.stat-widget .value {
    font-size: 2em;
    font-weight: bold;
    margin: 10px 0;
}

/* Loading Spinners */
.spinner {
    width: 40px;
    height: 40px;
    border: 4px solid var(--primary);
    border-top: 4px solid transparent;
    border-radius: 50%;
    animation: spin 1s linear infinite;
}

@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

/* Responsive Design */
@media (max-width: 768px) {
    .navbar {
        padding: 10px;
    }
    
    .server-card {
        margin: 10px;
    }
    
    .stat-widget {
        margin-bottom: 15px;
    }
}
EOL

    # Create theme configuration file
    output "Creating theme configuration file..."
    cat > public/themes/custom/theme.json <<EOL
{
  "name": "Custom Purple Theme",
  "version": "1.0.0",
  "author": "Loqman AS",
  "css": [
    "css/custom.css"
  ]
}
EOL

    # Check if theme.json exists in parent directory, create if needed
    if [ ! -f "public/themes/theme.json" ]; then
        output "Creating global theme configuration..."
        cat > public/themes/theme.json <<EOL
{
  "themes": [
    "custom",
    "default",
    "dark",
    "light",
    "blue",
    "minecraft",
    "jexactyl"
  ],
  "active": "custom"
}
EOL
    else
        # Update existing theme.json to include custom theme and set as active
        output "Updating global theme configuration..."
        # Create a temporary file with jq if available
        if command -v jq >/dev/null 2>&1; then
            jq '.themes |= if index("custom") then . else . + ["custom"] end | .active = "custom"' public/themes/theme.json > public/themes/theme.json.tmp
            mv public/themes/theme.json.tmp public/themes/theme.json
        else
            # Basic replacement if jq is not available
            sed -i 's/"active": "[^"]*"/"active": "custom"/g' public/themes/theme.json
            # Check if custom is already in themes list
            if ! grep -q '"custom"' public/themes/theme.json; then
                # Add custom to themes array - this is a basic approach that might need manual adjustment
                sed -i 's/"themes": \[/"themes": \["custom", /g' public/themes/theme.json
            fi
        fi
    fi

    # Make custom theme active in settings if database config exists
    if command -v mysql >/dev/null 2>&1; then
        output "Do you want to update the database to set custom theme as default? [y/N]"
        read -r db_choice
        if [[ "$db_choice" =~ ^[Yy]$ ]]; then
            output "Enter MySQL/MariaDB username (default: pterodactyl):"
            read -r db_user
            db_user=${db_user:-pterodactyl}
            
            output "Enter MySQL/MariaDB password:"
            read -rs db_pass
            
            output "Enter MySQL/MariaDB database name (default: panel):"
            read -r db_name
            db_name=${db_name:-panel}
            
            output "Updating theme setting in database..."
            mysql -u"$db_user" -p"$db_pass" "$db_name" -e "UPDATE settings SET value = 'custom' WHERE `key` = 'theme:active';"
            
            if [ $? -eq 0 ]; then
                success "Database updated successfully!"
            else
                warn "Failed to update database. You'll need to set the theme manually from admin panel."
            fi
        else
            output "Skipping database update. You can set the theme from admin panel."
        fi
    fi

    # Update admin dashboard theme
    output "Updating admin dashboard layout..."
    if [ -f "resources/views/admin/index.blade.php" ]; then
        cp -f resources/views/admin/index.blade.php resources/views/admin/index.blade.php.bak
        cat > resources/views/admin/index.blade.php <<EOL
@extends('layouts.admin')
@section('title', 'Admin Dashboard')

@section('content-header')
    <h1>Administrative Dashboard<small>A quick overview of your system.</small></h1>
    <ol class="breadcrumb">
        <li><a href="{{ route('admin.index') }}">Admin</a></li>
        <li class="active">Dashboard</li>
    </ol>
@endsection

@section('content')
<div class="row">
    <div class="col-xs-12">
        <div class="box box-info">
            <div class="box-header with-border">
                <h3 class="box-title">System Information</h3>
            </div>
            <div class="box-body">
                <div class="row">
                    @include('admin.statistics')
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

@section('footer-scripts')
    @parent
    {!! Theme::js('js/admin/dashboard.js') !!}
@endsection
EOL
    fi

    # Create a HTML test file to verify theme is working
    output "Creating test HTML file..."
    cat > public/themes/custom/test.html <<EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Custom Theme Test</title>
    <link rel="stylesheet" href="css/custom.css">
</head>
<body>
    <div style="text-align: center; padding: 50px;">
        <h1 style="color: var(--primary);">Custom Theme Test</h1>
        <p>If you're seeing this page styled with purple colors, your theme installation was successful!</p>
        <button class="btn-primary" style="padding: 10px 20px; border-radius: 5px; cursor: pointer;">Test Button</button>
    </div>
</body>
</html>
EOL

    # Set proper permissions
    output "Setting proper permissions..."
    detect_distro
    chown -R $WEB_USER:$WEB_USER /var/www/jexactyl/public/themes/custom
    chmod -R 755 /var/www/jexactyl/public/themes/custom
    
    # Clear Laravel cache
    output "Clearing application cache..."
    php artisan cache:clear
    php artisan view:clear
    php artisan config:clear
    
    # Restart services
    output "Restarting web services..."
    if systemctl is-active --quiet nginx; then
        systemctl restart nginx
    fi
    
    # Restart PHP-FPM (handling different versions)
    php_service=$(find /etc/init.d -name "php*-fpm" | head -n 1 | sed 's/\/etc\/init.d\///')
    if [ -n "$php_service" ]; then
        systemctl restart $php_service
    else
        # Try common PHP-FPM service names
        for ver in 8.2 8.1 8.0 7.4 7.3 7.2; do
            if systemctl is-active --quiet php$ver-fpm; then
                systemctl restart php$ver-fpm
            fi
        done
    fi

    success "Theme installation completed successfully!"
    output "Your Jexactyl panel now has a beautiful custom purple theme applied."
    output "You can test the theme by visiting: http://your-panel-url/themes/custom/test.html"
    output "If the theme isn't applied, please visit the admin panel to manually set 'custom' as your active theme."
    output "Or access the theme directly at: http://your-panel-url/themes/custom/css/custom.css"
}

# Main execution
clear
show_logo
confirm_theme_customization
