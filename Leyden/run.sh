#!/usr/bin/env bash
echo "0️⃣ Cleanup previous builds..."
rm -f -- *.aotconfig *.aot *.class *.jar


if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  source "$HOME/.sdkman/bin/sdkman-init.sh"
else
  echo "❌ SDKMAN not found — please install from https://sdkman.io/install"
  exit 1
fi

echo "🔄 Switching to Java 26.ea.19-open"
sdk use java  26.ea.19-open

APP_CLASS="LeydenBenchmark"
APP_JAR="LeydenBenchmark.jar"
AOT_CONFIG="LeydenBenchmark.aotconfig"
AOT_CACHE="LeydenBenchmark.aot"
ROUNDS=50

echo "1️⃣  Compile"
javac LeydenBenchmark.java

echo "2️⃣  Package JAR"
jar cvf "$APP_JAR" LeydenBenchmark.class

echo "3️⃣  Initial run"
java -cp "$APP_JAR" "$APP_CLASS"

echo "4️⃣  Training run (builds the optimization cache)"
java -XX:AOTMode=record -XX:AOTConfiguration="$AOT_CONFIG" \
  -cp "$APP_JAR" "$APP_CLASS"

echo "5️⃣  Create the AOT cache"
java -XX:AOTMode=create -XX:AOTConfiguration="$AOT_CONFIG" \
  -XX:AOTCache="$AOT_CACHE" -cp "$APP_JAR" "$APP_CLASS"

echo ""
echo "6️⃣  Running $ROUNDS times with AOT cache..."
total=0
total_external=0
for i in $(seq 1 $ROUNDS); do
  start=$(date +%s%N)
  output=$(java -XX:AOTCache="$AOT_CACHE" -cp "$APP_JAR" "$APP_CLASS")
  end=$(date +%s%N)
  external_time=$(( (end - start) / 1000000 ))
  total_external=$((total_external + external_time))

#  echo "$output"
  # Extract the time from output like "OK 91 1024 took=86ms"
  time=$(echo "$output" | grep -oE 'took=[0-9]+' | grep -oE '[0-9]+')
  total=$((total + time))
done
avg=$((total / ROUNDS))
avg_external=$((total_external / ROUNDS))
overhead=$((total_external - total))
avg_overhead=$((avg_external - avg))

echo ""
echo "📊 Runtime Statistics (with AOT cache):"
echo "   Internal time: total ${total} ms | avg ${avg} ms per run"
echo "   Total time:    total ${total_external} ms | avg ${avg_external} ms per run"
echo "   JVM overhead:  total ${overhead} ms | avg ${avg_overhead} ms per run"
echo ""
echo " ✅ Done. Completed $ROUNDS runs with AOT optimization."
