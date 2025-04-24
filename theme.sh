#!/bin/bash

# Thailand Codes Theme Customizer for Jexactyl
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
    echo "║               THAILAND CODES THEME CUSTOMIZER                 ║"
    echo "║                     By Loqman AS © 2024                      ║"
    echo "║                                                              ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Theme customization confirmation
confirm_theme_customization() {
    echo -e "${YELLOW}"
    echo "Would you like to customize the panel theme with Thailand Codes style? [y/N]"
    echo -e "${NC}"
    read -r choice
    case $choice in
        [Yy]*)  customize_theme ;;
        *)      output "Skipping theme customization." ;;
    esac
}

# Theme customization function
customize_theme() {
    output "Customizing panel theme with Thailand Codes style..."
    
    # Backup original files
    cd /var/www/jexactyl || exit
    mkdir -p backup/resources
    cp -r resources/views backup/resources/
    cp -r public/themes backup/public/
    
    # Update login page
    cat > resources/views/auth/login.blade.php <<EOL
@extends('layouts.auth')
@section('title', 'Login')

@section('content')
<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-gray-900 to-black py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full bg-gray-800 rounded-lg shadow-xl p-8 border border-purple-500/30">
        <div class="text-center">
            <img class="mx-auto h-24 w-auto" src="https://i.ibb.co/8dpsp69/Th-Logo.png" alt="Thailand Codes">
            <h2 class="mt-6 text-3xl font-extrabold text-white">Sign in to your account</h2>
            <p class="mt-2 text-sm text-gray-400">
                Or <a href="{{ route('auth.register') }}" class="font-medium text-purple-500 hover:text-purple-400">create a new account</a>
            </p>
        </div>
        
        <form class="mt-8 space-y-6" method="POST" action="{{ route('auth.login') }}">
            @csrf
            <div class="rounded-md shadow-sm -space-y-px">
                <div>
                    <label for="email" class="sr-only">Email address</label>
                    <input id="email" name="email" type="email" required class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-700 placeholder-gray-500 text-gray-100 rounded-t-md focus:outline-none focus:ring-purple-500 focus:border-purple-500 focus:z-10 sm:text-sm bg-gray-700" placeholder="Email address">
                </div>
                <div>
                    <label for="password" class="sr-only">Password</label>
                    <input id="password" name="password" type="password" required class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-700 placeholder-gray-500 text-gray-100 rounded-b-md focus:outline-none focus:ring-purple-500 focus:border-purple-500 focus:z-10 sm:text-sm bg-gray-700" placeholder="Password">
                </div>
            </div>

            <div class="flex items-center justify-between">
                <div class="flex items-center">
                    <input id="remember" name="remember" type="checkbox" class="h-4 w-4 text-purple-600 focus:ring-purple-500 border-gray-700 rounded bg-gray-700">
                    <label for="remember" class="ml-2 block text-sm text-gray-400">Remember me</label>
                </div>
                <div class="text-sm">
                    <a href="{{ route('auth.password') }}" class="font-medium text-purple-500 hover:text-purple-400">Forgot password?</a>
                </div>
            </div>

            <button type="submit" class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500">
                <span class="absolute left-0 inset-y-0 flex items-center pl-3">
                    <svg class="h-5 w-5 text-purple-500 group-hover:text-purple-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                        <path fill-rule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clip-rule="evenodd" />
                    </svg>
                </span>
                Sign in
            </button>
        </form>
    </div>
</div>
@endsection
EOL

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

    # Update theme colors
    cat > public/themes/pterodactyl/css/theme.css <<EOL
:root {
    --primary: #8960DC;
    --primary-light: #9D7DE5;
    --primary-dark: #4B248E;
    --secondary: #5B5B5B;
    --background: #000000;
    --background-light: #1A1A1A;
    --background-card: rgba(20, 20, 20, 0.8);
}

body {
    background: var(--background);
    color: #ffffff;
    font-family: 'Montserrat', sans-serif;
}

.navbar {
    background: var(--background-card);
    border-bottom: 1px solid var(--primary);
}

.btn-primary {
    background: var(--primary);
    border-color: var(--primary-dark);
}

.btn-primary:hover {
    background: var(--primary-dark);
    border-color: var(--primary);
}

.panel {
    background: var(--background-card);
    border: 1px solid var(--primary);
}

.panel-heading {
    background: var(--primary);
    color: #ffffff;
}

.form-control {
    background: var(--background-light);
    border: 1px solid var(--primary);
    color: #ffffff;
}

.form-control:focus {
    border-color: var(--primary-light);
    box-shadow: 0 0 0 0.2rem rgba(137, 96, 220, 0.25);
}
EOL

    # Set proper permissions
    if [ "$lsb_dist" = "ubuntu" ] || [ "$lsb_dist" = "debian" ]; then
        chown -R www-data:www-data /var/www/jexactyl
    elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        chown -R nginx:nginx /var/www/jexactyl
    fi

    success "Theme customization completed successfully!"
    output "Your panel now has the Thailand Codes theme applied."
}

# Main execution
clear
show_logo
confirm_theme_customization
