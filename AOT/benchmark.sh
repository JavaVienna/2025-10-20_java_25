#!/bin/bash
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  source "$HOME/.sdkman/bin/sdkman-init.sh"
else
  echo "❌ SDKMAN not found — please install from https://sdkman.io/install"
  exit 1
fi

echo "🔄 Switching to Java 25"
sdk use java 25-amzn >/dev/null

echo "🧪 Running 50 runs WITHOUT AOT..."
start_no_aot=$(date +%s%N)
for i in {1..50}; do
  java aot > /dev/null
done
end_no_aot=$(date +%s%N)
elapsed_no_aot=$(( (end_no_aot - start_no_aot) / 1000000 ))

echo "⏱️  Without AOT total: ${elapsed_no_aot} ms (avg $((elapsed_no_aot / 50)) ms per run)"

echo ""
echo "⚡ Running 50 runs WITH AOT..."
start_aot=$(date +%s%N)
for i in {1..50}; do
  java -XX:AOTCache=aot.aot aot > /dev/null
done
end_aot=$(date +%s%N)
elapsed_aot=$(( (end_aot - start_aot) / 1000000 ))

echo "🚀 With AOT total: ${elapsed_aot} ms (avg $((elapsed_aot / 50)) ms per run)"

echo ""
echo "📊 Summary:"
echo "   Without AOT: ${elapsed_no_aot} ms"
echo "   With AOT:    ${elapsed_aot} ms"
diff=$((elapsed_no_aot - elapsed_aot))
if [ $diff -gt 0 ]; then
  echo "   ✅ AOT faster by ${diff} ms total (~$((diff / 50)) ms per run)"
else
  echo "   ⚠️ No visible improvement (${diff} ms difference)"
fi
