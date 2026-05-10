#!/bin/bash
# build-hybrid.sh — Копирует HTML-прототипы в dist/ для Capacitor
# Использование: ./build-hybrid.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/../05_ui_screens/main-screens"
DIST_DIR="$SCRIPT_DIR/dist"

echo "🔨 AIDiet Hybrid Build"
echo "   Source: $SRC_DIR"
echo "   Output: $DIST_DIR"

# 1. Очищаем dist/
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# 2. Копируем HTML, JS, CSS, и ассеты
echo "📂 Копируем HTML файлы..."
cp "$SRC_DIR"/*.html "$DIST_DIR/" 2>/dev/null || true

echo "📂 Копируем JS файлы..."
cp "$SRC_DIR"/*.js "$DIST_DIR/" 2>/dev/null || true

echo "📂 Копируем CSS файлы..."
cp "$SRC_DIR"/*.css "$DIST_DIR/" 2>/dev/null || true

echo "📂 Копируем изображения..."
cp "$SRC_DIR"/*.png "$DIST_DIR/" 2>/dev/null || true
cp "$SRC_DIR"/*.jpg "$DIST_DIR/" 2>/dev/null || true
cp "$SRC_DIR"/*.svg "$DIST_DIR/" 2>/dev/null || true
cp "$SRC_DIR"/*.ico "$DIST_DIR/" 2>/dev/null || true

echo "📂 Копируем JSON данные..."
cp "$SRC_DIR"/*.json "$DIST_DIR/" 2>/dev/null || true

# 2.5 Копируем подпапки (assets/ с логотипами и иконками)
if [ -d "$SRC_DIR/assets" ]; then
  echo "📂 Копируем assets/..."
  cp -r "$SRC_DIR/assets" "$DIST_DIR/"
fi

# 3. Копируем capacitor-bridge.js (мост для нативных API)
if [ -f "$SCRIPT_DIR/src/capacitor-bridge.js" ]; then
  echo "🌉 Копируем Capacitor Bridge..."
  cp "$SCRIPT_DIR/src/capacitor-bridge.js" "$DIST_DIR/"
fi

# 4. Исключаем dev-only файлы
rm -f "$DIST_DIR/aidiet-dev.js"
rm -f "$DIST_DIR/vercel.json"
rm -f "$DIST_DIR/.gitignore"

# 5. Считаем результат
HTML_COUNT=$(ls "$DIST_DIR"/*.html 2>/dev/null | wc -l | tr -d ' ')
JS_COUNT=$(ls "$DIST_DIR"/*.js 2>/dev/null | wc -l | tr -d ' ')
CSS_COUNT=$(ls "$DIST_DIR"/*.css 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "✅ Build complete!"
echo "   HTML: $HTML_COUNT files"
echo "   JS:   $JS_COUNT files"
echo "   CSS:  $CSS_COUNT files"
echo ""
echo "Следующий шаг: npx cap sync"
