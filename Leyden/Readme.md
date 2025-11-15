# Leyden Workflow

# 1. Install Leyden (Java 26 EA, NOT Java 25!)

1- sdk install java 26.ea.19-open
2- sdk use java 26.ea.19-open
# 2. Compile and create JAR
3- javac LeydenBenchmark.java
4- jar cvf LeydenBenchmark.jar LeydenBenchmark.class

# 3. Test baseline run
java -cp LeydenBenchmark.jar LeydenBenchmark

# 4. Training run (builds the optimization cache)
java -XX:AOTMode=record -XX:AOTConfiguration=LeydenBenchmark.aotconfig -cp LeydenBenchmark.jar LeydenBenchmark

# 5. Create the AOT cache
java -XX:AOTMode=create -XX:AOTConfiguration=LeydenBenchmark.aotconfig -XX:AOTCache=LeydenBenchmark.aot -cp LeydenBenchmark.jar LeydenBenchmark

# 6. Production run (loads the optimized cache)
java -XX:AOTCache=LeydenBenchmark.aot -cp LeydenBenchmark.jar LeydenBenchmark












# SETUP - Install Leyden (Java 26 EA, not 25!)
sdk install java 26.ea.19-open
sdk use java 26.ea.19-open

# STEP 1: Compile and create JAR
javac LeydenBenchmark.java
jar cvf LeydenBenchmark.jar LeydenBenchmark.class

# STEP 2: Test basic run
java -cp LeydenBenchmark.jar LeydenBenchmark

# ===== OPTION A: CDS ONLY (if you just want CDS) =====
# Create CDS archive
java -Xshare:dump \
-XX:SharedArchiveFile=LeydenBenchmark.jsa \
-cp LeydenBenchmark.jar LeydenBenchmark

# Run with CDS
java -Xshare:on \
-XX:SharedArchiveFile=LeydenBenchmark.jsa \
-cp LeydenBenchmark.jar LeydenBenchmark

# ===== OPTION B: LEYDEN ONLY (full Leyden workflow) =====
# Step 1: Training run - records what needs to be optimized
java -XX:AOTMode=record \
-XX:AOTConfiguration=LeydenBenchmark.aotconfig \
-cp LeydenBenchmark.jar LeydenBenchmark

# Step 2: Create AOT cache - generates optimized snapshot
java -XX:AOTMode=create \
-XX:AOTConfiguration=LeydenBenchmark.aotconfig \
-XX:AOTCache=LeydenBenchmark.aot \
-cp LeydenBenchmark.jar LeydenBenchmark

# Step 3: Production run - uses optimized cache (FAST!)
java -XX:AOTCache=LeydenBenchmark.aot \
-cp LeydenBenchmark.jar LeydenBenchmark

# ===== OPTION C: CDS + LEYDEN COMBINED (maximum optimization) =====
# Create CDS
java -Xshare:dump \
-XX:SharedArchiveFile=LeydenBenchmark.jsa \
-cp LeydenBenchmark.jar LeydenBenchmark

# Leyden training run WITH CDS
java -XX:AOTMode=record \
-XX:AOTConfiguration=LeydenBenchmark.aotconfig \
-Xshare:on -XX:SharedArchiveFile=LeydenBenchmark.jsa \
-cp LeydenBenchmark.jar LeydenBenchmark

# Create AOT cache
java -XX:AOTMode=create \
-XX:AOTConfiguration=LeydenBenchmark.aotconfig \
-XX:AOTCache=LeydenBenchmark.aot \
-Xshare:on -XX:SharedArchiveFile=LeydenBenchmark.jsa \
-cp LeydenBenchmark.jar LeydenBenchmark

# Production run with both
java -XX:AOTCache=LeydenBenchmark.aot \
-Xshare:on -XX:SharedArchiveFile=LeydenBenchmark.jsa \
-cp LeydenBenchmark.jar LeydenBenchmark