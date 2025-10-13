#!/usr/bin/env bash
# set -euo pipefail

if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  source "$HOME/.sdkman/bin/sdkman-init.sh"
else
  echo "❌ SDKMAN not found — please install from https://sdkman.io/install"
  exit 1
fi

echo "🔄 Switching to Java 25"
sdk use java 25-amzn >/dev/null

APP_CLASS="aot"                 # your main class (e.g., package.Main)
APP_JAR="app.jar"
OUT_DIR="leyden-image"
RUNTIME_DIR="$OUT_DIR/runtime"
CDS_ARCHIVE="$OUT_DIR/app-cds.jsa"
AOT_CACHE="$OUT_DIR/app.aot"

echo "1) Compile"
javac aot.java

echo "2) Package JAR (with Main-Class)"
jar --create --file "$APP_JAR" --main-class "$APP_CLASS" aot.class

echo "3) Find required JDK modules"
MODS=$(jdeps --print-module-deps --multi-release 25 "$APP_JAR")
echo "   Modules: $MODS"

echo "4) Create trimmed runtime with jlink"
rm -rf "$RUNTIME_DIR"
jlink \
  --add-modules "$MODS" \
  --output "$RUNTIME_DIR" \
  --strip-java-debug-attributes \
  --no-header-files \
  --no-man-pages \
  --compress=2

echo "5) Create CDS archive (two-step: classlist -> archive)"
rm -f "$OUT_DIR"/classes.lst "$CDS_ARCHIVE"
mkdir -p "$OUT_DIR"

# 5a) Record class list by doing a training run
"$RUNTIME_DIR/bin/java" \
  -Xshare:off \
  -XX:DumpLoadedClassList="$OUT_DIR/classes.lst" \
  -cp "$APP_JAR" "$APP_CLASS" >/dev/null

# 5b) Build the archive from the class list
"$RUNTIME_DIR/bin/java" \
  -Xshare:dump \
  -XX:SharedClassListFile="$OUT_DIR/classes.lst" \
  -XX:SharedArchiveFile="$CDS_ARCHIVE" \
  -cp "$APP_JAR"

echo "6) Create AOT cache (Leyden one-shot)"
"$RUNTIME_DIR/bin/java" \
  -XX:AOTCacheOutput="$AOT_CACHE" \
  -cp "$APP_JAR" "$APP_CLASS" >/dev/null

# (Optional) tiny launcher script
cat > "$OUT_DIR/run.sh" <<'EOF'
#!/usr/bin/env bash
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  source "$HOME/.sdkman/bin/sdkman-init.sh"
else
  echo "❌ SDKMAN not found — please install from https://sdkman.io/install"
  exit 1
fi

echo "🔄 Switching to Java 25"
sdk use java 25-amzn >/dev/null

DIR="$(cd "$(dirname "$0")" && pwd)"
JAVA="$DIR/runtime/bin/java"
APP_JAR="$DIR/../app.jar"
MAIN="aot"

MODE="${1:-plain}"   # usage: ./run.sh [plain|cds|aot]

case "$MODE" in
  plain)
    exec "$JAVA" -cp "$APP_JAR" "$MAIN" "${@:2}"
    ;;
  cds)
    exec "$JAVA" -Xshare:on -XX:SharedArchiveFile="$DIR/app-cds.jsa" -cp "$APP_JAR" "$MAIN" "${@:2}"
    ;;
  aot)
    exec "$JAVA" -XX:AOTCache="$DIR/app.aot" -cp "$APP_JAR" "$MAIN" "${@:2}"
    ;;
  *)
    echo "Usage: $0 [plain|cds|aot] [args...]"
    exit 1
    ;;
esac
EOF
chmod +x "$OUT_DIR/run.sh"

echo
echo "✅ Done. Run your Leyden image with:"
echo "   $OUT_DIR/run.sh"
