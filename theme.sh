#!/bin/bash

# Jexactyl Theme Customizer
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

# Theme customization confirmation
confirm_theme_customization() {
    echo -e "${YELLOW}"
    echo "Would you like to customize the panel theme? [y/N]"
    echo -e "${NC}"
    read -r choice
    case $choice in
        [Yy]*)  customize_theme ;;
        *)      output "Skipping theme customization." ;;
    esac
}

# Theme customization function
customize_theme() {
    output "Customizing panel theme..."
    
    # Backup original files
    cd /var/www/jexactyl || exit
    mkdir -p backup/resources
    cp -r resources/views backup/resources/
    
    # Create theme directories if they don't exist
    mkdir -p public/assets/css
    # Also back up existing theme files if they exist
    if [ -d "public/assets/css" ]; then
        mkdir -p backup/public/assets
        cp -r public/assets/css backup/public/assets/
    fi
    
    # Update admin dashboard theme
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

    # Update theme colors and styles - FIXED PATH
    cat > public/assets/css/theme.css <<EOL
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

    # Set proper permissions
    if command -v lsb_release >/dev/null 2>&1; then
        lsb_dist="$(lsb_release -is | tr '[:upper:]' '[:lower:]')"
    elif [ -f /etc/os-release ]; then
        lsb_dist="$(. /etc/os-release && echo "$ID" | tr '[:upper:]' '[:lower:]')"
    fi
    
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        chown -R www-data:www-data /var/www/jexactyl
    elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        chown -R nginx:nginx /var/www/jexactyl
    fi

    success "Theme customization completed successfully!"
    output "Your panel now has a beautiful custom theme applied."
    
    # Restart services to apply changes
    systemctl restart nginx
    systemctl restart php*-fpm
}

# Main execution
clear
show_logo
confirm_theme_customization
