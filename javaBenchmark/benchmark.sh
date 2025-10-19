#!/bin/bash
# Benchmark same app across Java 17, 21, and 25 (Amazon Corretto builds)
# Load SDKMAN environment
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  source "$HOME/.sdkman/bin/sdkman-init.sh"
else
  echo "❌ SDKMAN not found — please install from https://sdkman.io/install"
  exit 1
fi

APP="JavaBenchmark"
ROUNDS=50
VERSIONS=("17.0.16-amzn" "21.0.8-amzn" "25-amzn")

echo "🏁 Benchmarking $APP.java for $ROUNDS runs each..."
echo

for v in "${VERSIONS[@]}"; do
  echo "🔄 Switching to Java $v"
  sdk use java "$v" >/dev/null

  javac "$APP.java" || { echo "Compilation failed for Java $v"; exit 1; }

  echo "▶️ Running $APP $ROUNDS times..."
  total=0
  total_external=0
  for i in $(seq 1 $ROUNDS); do
    start=$(date +%s%N)
    output=$(java "$APP")
    end=$(date +%s%N)
    external_time=$(( (end - start) / 1000000 ))
    total_external=$((total_external + external_time))

    # Extract the time from output like "OK 91 1024 took=86ms"
    time=$(echo "$output" | grep -oE 'took=[0-9]+' | grep -oE '[0-9]+')
    total=$((total + time))
  done
  avg=$((total / ROUNDS))
  avg_external=$((total_external / ROUNDS))
  overhead=$((total_external - total))
  avg_overhead=$((avg_external - avg))

  echo "📊 Java $v:"
  echo "   Internal time: total ${total} ms | avg ${avg} ms per run"
  echo "   Total time:    total ${total_external} ms | avg ${avg_external} ms per run"
  echo "   JVM overhead:  total ${overhead} ms | avg ${avg_overhead} ms per run"
  echo
done

echo "✅ Done."
