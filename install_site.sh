#!/bin/bash

# Проверка прав root
if [ "$(id -u)" != "0" ]; then
    echo "❌ Запускай скрипт через sudo!"
    exit 1
fi

# --- НАСТРОЙКИ ---
INSTALL_DIR="/opt/gl1ch_hub"
# Ссылка на "сырые" файлы в твоем репозитории
REPO_RAW="https://raw.githubusercontent.com/PavloMakaro/Mysite/main"
SERVICE_NAME="gl1ch_hub.service"

echo "🚀 Начинаем установку Gl1ch Hub (Fix Structure)..."

# 1. Остановка старого сервиса
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "🛑 Останавливаю текущий сайт..."
    systemctl stop $SERVICE_NAME
    systemctl disable $SERVICE_NAME
else
    echo "Сервис не запущен, продолжаем..."
fi

# 2. Подготовка папок (ВАЖНО: Создаем папку templates)
echo "🧹 Чистим и создаем директории..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/templates" # <-- Создаем папку для HTML
cd "$INSTALL_DIR" || exit 1

# 3. Обновление пакетов
echo "📦 Установка Python..."
apt update -y
apt install python3-full -y

# 4. Скачивание файлов с GitHub
echo "⬇️ Скачивание файлов..."

# Качаем app.py в корень
wget -qO app.py "$REPO_RAW/app.py"
if [ $? -ne 0 ]; then echo "❌ Ошибка: Не найден app.py"; exit 1; fi

# Качаем HTML файлы и СРАЗУ кладем их в папку templates
# (Так как на GitHub они лежат в корне, качаем из корня, но сохраняем в папку)
wget -qO templates/index.html "$REPO_RAW/index.html"
if [ $? -ne 0 ]; then echo "❌ Ошибка: Не найден index.html"; exit 1; fi

wget -qO templates/admin.html "$REPO_RAW/admin.html"
if [ $? -ne 0 ]; then echo "❌ Ошибка: Не найден admin.html"; exit 1; fi

echo "✅ Файлы скачаны и разложены правильно."

# 5. Виртуальное окружение
echo "🐍 Настройка venv..."
python3 -m venv venv
source venv/bin/activate

echo "📚 Установка Flask..."
pip install flask

# 6. Создание Systemd сервиса
echo "⚙️ Настройка автозапуска..."
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"

cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Gl1ch Hub Website
After=network.target

[Service]
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python3 $INSTALL_DIR/app.py
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# 7. Запуск
echo "🔥 Запуск..."
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

sleep 3

# 8. Проверка работает ли оно
echo "---------------------------------------------------"
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "✅ СТАТУС: АКТИВЕН"
    echo "🌍 Пробуй открыть в браузере: http://Tgbo1.ignorelist.com"
else
    echo "⚠️ ОШИБКА: Сервис не запустился."
    echo "Вот последние ошибки из лога:"
    journalctl -u $SERVICE_NAME -n 10 --no-pager
fi
