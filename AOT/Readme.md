# AOT Java 25

1- sdk install java 25-amzn
2- sdk use java 25-amzn
3- javac AotBenchMark.java
4- java -XX:AOTCacheOutput=AotBenchMark.aot AotBenchMark
5- java -XX:AOTCache=AotBenckmark.aot AotBenchMark


That replaces the old (removed) jaotc/-XX:+AOTCompile flow.

If you prefer the explicit two-step flow, you can still do it:

# 1) record a training run
java -XX:AOTMode=record -XX:AOTConfiguration=app.aotconf AotBenckmark
# 2) create the cache
java -XX:AOTMode=create -XX:AOTConfiguration=app.aotconf -XX:AOTCache=app.aot
# 3) run with the cache
java -XX:AOTCache=app.aot AotBenckmark