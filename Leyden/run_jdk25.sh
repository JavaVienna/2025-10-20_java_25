#!/usr/bin/env bash
echo "0️⃣ Cleanup previous builds..."
rm -f -- *.aotconfig *.aot *.class *.jar


if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  source "$HOME/.sdkman/bin/sdkman-init.sh"
else
  echo "❌ SDKMAN not found — please install from https://sdkman.io/install"
  exit 1
fi

echo "🔄 Switching to Java 25"
sdk use java 25-open

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
for i in $(seq 1 $ROUNDS); do
  output=$(java -XX:AOTCache="$AOT_CACHE" -cp "$APP_JAR" "$APP_CLASS")
#  echo "$output"
  # Extract the time from output like "OK 91 1024 took=86ms"
  time=$(echo "$output" | grep -oE 'took=[0-9]+' | grep -oE '[0-9]+')
  total=$((total + time))
done
avg=$((total / ROUNDS))

echo ""
echo "📊 Runtime Statistics (Program Execution Time):"
echo "   Total: ${total} ms"
echo "   Average: ${avg} ms per run"
echo ""
echo " ✅ Done. Completed $ROUNDS runs with AOT optimization."
