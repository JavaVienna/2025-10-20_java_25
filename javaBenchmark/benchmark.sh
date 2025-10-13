#!/bin/bash
# Benchmark same app across Java 17, 21, and 25 (Amazon Corretto builds)
# Load SDKMAN environment
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  source "$HOME/.sdkman/bin/sdkman-init.sh"
else
  echo "❌ SDKMAN not found — please install from https://sdkman.io/install"
  exit 1
fi

APP="aot"
ROUNDS=50
VERSIONS=("17.0.8-amzn" "21.0.8-amzn" "25-amzn")

echo "🏁 Benchmarking $APP.java for $ROUNDS runs each..."
echo

for v in "${VERSIONS[@]}"; do
  echo "🔄 Switching to Java $v"
  sdk use java "$v" >/dev/null

  javac "$APP.java" || { echo "Compilation failed for Java $v"; exit 1; }

  echo "▶️ Running $APP $ROUNDS times..."
  start=$(date +%s%N)
  for i in $(seq 1 $ROUNDS); do
    java "$APP" > /dev/null
  done
  end=$(date +%s%N)
  elapsed=$(( (end - start) / 1000000 ))
  avg=$(( elapsed / ROUNDS ))

  echo "📊 Java $v: total ${elapsed} ms | avg ${avg} ms per run"
  echo
done

echo "✅ Done."
