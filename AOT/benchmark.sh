#!/bin/bash
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  source "$HOME/.sdkman/bin/sdkman-init.sh"
else
  echo "❌ SDKMAN not found — please install from https://sdkman.io/install"
  exit 1
fi

echo "🔄 Switching to Java 25"
sdk use java 25-amzn >/dev/null

ROUNDS=50

echo "🧪 Running $ROUNDS runs WITHOUT AOT..."
total_no_aot=0
total_no_aot_external=0
for i in $(seq 1 $ROUNDS); do
  start=$(date +%s%N)
  output=$(java AotBenchMark)
  end=$(date +%s%N)
  external_time=$(( (end - start) / 1000000 ))
  total_no_aot_external=$((total_no_aot_external + external_time))

  # Extract the time from output like "OK 91 1024 took=86ms"
  time=$(echo "$output" | grep -oE 'took=[0-9]+' | grep -oE '[0-9]+')
  total_no_aot=$((total_no_aot + time))
done
avg_no_aot=$((total_no_aot / ROUNDS))
avg_no_aot_external=$((total_no_aot_external / ROUNDS))

echo "⏱️  Without AOT (internal): ${total_no_aot} ms (avg ${avg_no_aot} ms per run)"
echo "⏱️  Without AOT (total):    ${total_no_aot_external} ms (avg ${avg_no_aot_external} ms per run)"
echo "⏱️  JVM overhead:           $((total_no_aot_external - total_no_aot)) ms (avg $((avg_no_aot_external - avg_no_aot)) ms per run)"

echo ""
echo "⚡ Running $ROUNDS runs WITH AOT..."
total_aot=0
total_aot_external=0
for i in $(seq 1 $ROUNDS); do
  start=$(date +%s%N)
  output=$(java -XX:AOTCache=AotBenckmark.aot AotBenchMark)
  end=$(date +%s%N)
  external_time=$(( (end - start) / 1000000 ))
  total_aot_external=$((total_aot_external + external_time))

  # Extract the time from output like "OK 91 1024 took=86ms"
  time=$(echo "$output" | grep -oE 'took=[0-9]+' | grep -oE '[0-9]+')
  total_aot=$((total_aot + time))
done
avg_aot=$((total_aot / ROUNDS))
avg_aot_external=$((total_aot_external / ROUNDS))

echo "🚀 With AOT (internal): ${total_aot} ms (avg ${avg_aot} ms per run)"
echo "🚀 With AOT (total):    ${total_aot_external} ms (avg ${avg_aot_external} ms per run)"
echo "🚀 JVM overhead:        $((total_aot_external - total_aot)) ms (avg $((avg_aot_external - avg_aot)) ms per run)"

echo ""
echo "📊 Summary (Total Time Including JVM Startup):"
echo "   Without AOT: ${total_no_aot_external} ms (avg ${avg_no_aot_external} ms)"
echo "   With AOT:    ${total_aot_external} ms (avg ${avg_aot_external} ms)"
diff=$((total_no_aot_external - total_aot_external))
if [ $diff -gt 0 ]; then
  echo "   ✅ AOT faster by ${diff} ms total (~$((diff / ROUNDS)) ms per run)"
else
  echo "   ⚠️ No visible improvement (${diff} ms difference)"
fi
