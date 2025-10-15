#!/bin/bash
# Compare Java 17, 21, 25, and 25+COH on a memory-heavy retained-object test

if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  source "$HOME/.sdkman/bin/sdkman-init.sh"
else
  echo "❌ SDKMAN not found — install from https://sdkman.io/install"
  exit 1
fi

APP="CohBench"
SRC="${APP}.java"
N="${N:-10000000}"                 # can override: N=20000000 ./run.sh
HEAP="${HEAP:-2g}"                 # fixed heap to reduce GC noise
VERSIONS=("17.0.8-amzn" "21.0.8-amzn" "25-amzn")

for v in "${VERSIONS[@]}"; do

  echo "🔄 Switching to Java $v"
  sdk use java "$v" >/dev/null

  echo "🏁 Building $SRC and benchmarking with N=$N objects, heap=${HEAP}..."
  javac "$SRC" || { echo "Compilation failed"; exit 1; }
  echo
  echo "🔄 Switching to Java $v"
  sdk use java "$v" >/dev/null

  echo "▶️ $v"
  java -Xms${HEAP} -Xmx${HEAP} -DN=${N} ${APP}
  echo
done

# Java 25 + COH
sdk use java "25-amzn" >/dev/null
echo "🔄 Switching to Java 25 (COH=ON)"
java -Xms${HEAP} -Xmx${HEAP} -DN=${N} -XX:+UseCompactObjectHeaders ${APP}
echo
echo "✅ Done."