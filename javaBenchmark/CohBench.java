public class CohBench {
    // Override with -DN=20000000 for bigger runs
    static final int N = Integer.getInteger("N", 10_000_000);

    static final class Pair {
        int a, b;
        Pair(int a, int b) { this.a = a; this.b = b; }
    }

    static Pair[] hold;

    public static void main(String[] args) throws Exception {
        Runtime rt = Runtime.getRuntime();
        forceGC();
        long before = used(rt);

        hold = new Pair[N];
        for (int i = 0; i < N; i++) hold[i] = new Pair(i, i);

        // Ensure they’re retained and JIT doesn’t optimize away
        blackhole(hold[hold.length - 1]);

        forceGC();
        long after = used(rt);

        long retained = Math.max(0, after - before);
        System.out.println("Objects: " + N);
        System.out.println("Retained bytes: " + retained);
        System.out.println("~Bytes/object: " + (retained / (double) N));
    }

    static void forceGC() throws InterruptedException {
        for (int i = 0; i < 3; i++) {
            System.gc();
            Thread.sleep(50);
        }
    }

    static long used(Runtime rt) {
        return rt.totalMemory() - rt.freeMemory();
    }

    static volatile Object sink;
    static void blackhole(Object o) { sink = o; }
}
