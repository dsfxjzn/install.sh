#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$HOME/HoMeLaNd"
LUA_BIN="lua5.2"

trap 'echo "❌ فشل التنفيذ بالسطر $LINENO. راجع الخطأ أعلاه."; exit 1' ERR

echo "===================================="
echo "   HoMeLaNd - Ubuntu 22.04"
echo "===================================="

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "❌ مجلد المشروع غير موجود: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

if ! sudo -v; then
    echo "❌ تعذر الحصول على صلاحيات sudo."
    exit 1
fi

install_dependencies() {
    echo "📦 تحديث قوائم الحزم..."
    sudo apt-get update

    echo "📦 تثبيت المكتبات والأدوات..."
    sudo apt-get install -y \
        software-properties-common \
        build-essential \
        g++ \
        make \
        autoconf \
        git \
        curl \
        unzip \
        screen \
        htop \
        redis-server \
        libreadline-dev \
        libconfig-dev \
        libssl-dev \
        libstdc++6 \
        libevent-dev \
        libjansson-dev \
        libexpat1-dev \
        libcurl4-openssl-dev \
        lua5.2 \
        liblua5.2-dev \
        luarocks \
        lua-socket \
        lua-sec \
        lua-expat \
        lua-lgi \
        libnotify-dev

    command -v "$LUA_BIN" >/dev/null || {
        echo "❌ Lua 5.2 غير متوفر."
        exit 1
    }

    echo "📦 تثبيت مكتبات Lua الإضافية..."
    sudo luarocks --lua-version=5.2 install luasocket
    sudo luarocks --lua-version=5.2 install luasec
    sudo luarocks --lua-version=5.2 install redis-lua
    sudo luarocks --lua-version=5.2 install Lua-cURL

    echo "🔴 تشغيل Redis..."
    sudo systemctl enable --now redis-server

    echo "✅ انتهى تثبيت المتطلبات."
}

run_source() {
    echo "🔍 فحص ملفات السورس..."

    for file in tg HoMeLaNd.lua BK; do
        if [[ ! -f "$file" ]]; then
            echo "❌ الملف $file غير موجود."
            exit 1
        fi
    done

    chmod +x tg BK

    if [[ -f "HoMeLaNd" ]]; then
        chmod +x HoMeLaNd
    fi

    echo "🔍 فحص خدمة Redis..."
    if ! redis-cli ping | grep -qx "PONG"; then
        echo "❌ Redis لا يستجيب."
        exit 1
    fi

    echo "🚀 تشغيل HoMeLaNd.lua..."
    "$LUA_BIN" HoMeLaNd.lua

    echo "🚀 تشغيل BK..."
    ./BK
}

case "${1:-run}" in
    install)
        install_dependencies
        run_source
        ;;
    run)
        run_source
        ;;
    *)
        echo "طريقة الاستخدام:"
        echo "  bash install.sh install"
        echo "  bash install.sh run"
        exit 2
        ;;
esac
