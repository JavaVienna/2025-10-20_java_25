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

cd leyden-image || exit 1
echo "📁 Working directory: $(pwd)"

# Config
ROUNDS="${1:-50}"                    # usage: ./benchmark.sh [ROUNDS]
DIR="$(cd "$(dirname "$0")" && pwd)" # points to leyden-image/
JAVA="$DIR/runtime/bin/java"
RUN="$DIR/run.sh"
APP_JAR="$(realpath "$DIR/../app.jar")"
MAIN="aot"

echo "🏁 Benchmarking $MAIN with $ROUNDS runs per mode (plain | cds | aot)"
echo "📦 App JAR: $APP_JAR"
echo

# Ensure app.jar exists (best-effort compile if missing)
if [ ! -f "$APP_JAR" ]; then
  echo "🔧 app.jar not found; trying to build from ../$MAIN.java"
  if [ -f "$DIR/../$MAIN.java" ]; then
    ( cd "$DIR/.."
      javac "$MAIN.java"
      jar --create --file app.jar --main-class "$MAIN" "$MAIN.class"
    )
  else
    echo "❌ Missing $APP_JAR and ../$MAIN.java — please provide your JAR or source."
    exit 1
  fi
fi

# Ensure run.sh exists
if [ ! -x "$RUN" ]; then
  echo "❌ $RUN not found or not executable."
  exit 1
fi

# Prepare CDS archive with absolute classpath if missing
CDS="$DIR/app-cds.jsa"
if [ ! -f "$CDS" ]; then
  echo "📚 Creating CDS archive (absolute classpath)"
  "$JAVA" -Xshare:dump \
          -XX:SharedArchiveFile="$CDS" \
          -cp "$APP_JAR"
fi

# Prepare AOT cache if missing
AOT="$DIR/app.aot"
if [ ! -f "$AOT" ]; then
  echo "⚙️  Creating AOT cache (one-shot training run)"
  "$JAVA" -XX:AOTCacheOutput="$AOT" -cp "$APP_JAR" "$MAIN" >/dev/null
fi

bench() {
  local mode="$1"
  local rounds="$2"
  echo "▶️  $mode: warming up once..."
  "$RUN" "$mode" >/dev/null || true

  echo "⏱️  Running $rounds times ($mode)..."
  local start end elapsed avg
  start=$(date +%s%N)
  for i in $(seq 1 "$rounds"); do
    "$RUN" "$mode" >/dev/null
  done
  end=$(date +%s%N)
  elapsed=$(( (end - start) / 1000000 ))
  avg=$(( elapsed / rounds ))
  echo "📊 $mode total: ${elapsed} ms (avg ${avg} ms/run)"
  echo
}

bench plain "$ROUNDS"
bench cds   "$ROUNDS"
bench aot   "$ROUNDS"

cd - >/dev/null || exit 1
echo "✅ Done."
