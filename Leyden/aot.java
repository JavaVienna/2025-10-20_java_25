import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.regex.Pattern;

public class aot {
    public static void main(String[] args) throws Exception {
        long t0 = System.nanoTime();

        var now = ZonedDateTime.now(ZoneId.systemDefault());
        var fmt = DateTimeFormatter.ISO_ZONED_DATE_TIME;
        var s = fmt.format(now);

        var p = Pattern.compile("([0-9T:\\-+.]+)\\[(.+)]");
        var m = p.matcher(s);
        String zone = m.find() ? m.group(2) : "UTC";

        var list = new ArrayList<>(List.of("alpha", "beta", zone, UUID.randomUUID().toString()));
        Collections.sort(list);
        String joined = String.join("|", list);

        var md = MessageDigest.getInstance("SHA-256");
        byte[] dig = md.digest(joined.getBytes(StandardCharsets.UTF_8));

        BigInteger prime = BigInteger.probablePrime(1024, new Random(42));

        long tookMs = (System.nanoTime() - t0) / 1_000_000;
        System.out.println("OK " + dig[0] + " " + prime.bitLength() + " took=" + tookMs + "ms");
    }
}
