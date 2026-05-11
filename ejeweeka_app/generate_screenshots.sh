#!/bin/bash
# Скрипт для автоматической генерации скриншотов через Flutter Integration Test

echo "📸 Подготовка к генерации скриншотов..."

# Убедимся, что зависимости установлены
flutter pub get

# Проверяем подключенные устройства
DEVICES=$(flutter devices | grep -E "ios|android|simulator|emulator" | wc -l)
if [ "$DEVICES" -eq 0 ]; then
    echo "❌ Ошибка: Нет запущенных симуляторов или эмуляторов."
    echo "Пожалуйста, запустите iOS Simulator (например, iPhone 15 Pro Max) и повторите."
    exit 1
fi

echo "🚀 Запуск интеграционного теста..."
echo "Скриншоты будут сохранены в папке 'screenshots/'"

# Создаем папку, если её нет
mkdir -p screenshots

# Запускаем драйвер
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshot_test.dart

echo "✅ Завершено! Проверьте папку 'screenshots/'"
