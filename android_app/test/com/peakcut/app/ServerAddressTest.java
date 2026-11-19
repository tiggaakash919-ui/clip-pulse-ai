package com.peakcut.app;

/** Lightweight host-JVM checks for server URL entry and normalization. */
public final class ServerAddressTest {
    public static void main(String[] args) {
        expect("https://studio.example/app", "studio.example");
        expect("https://studio.example/app", "https://studio.example/");
        expect("https://studio.example/clips/app", "https://studio.example/clips/");
        expect("http://192.168.1.20:8766/app", "192.168.1.20");
        expect("http://localhost:8766/app", "localhost");
        expect("http://studio.example/app", "http://studio.example");
        reject("");
        reject("ftp://studio.example");
        reject("https://user:password@studio.example");
        reject("https://studio.example:99999");
        reject("https://studio.example/app?token=x");
    }

    private static void expect(String expected, String input) {
        String actual = ServerAddress.normalize(input, 8766);
        if (!expected.equals(actual)) {
            throw new AssertionError(input + " normalized to " + actual + ", expected " + expected);
        }
    }

    private static void reject(String input) {
        try {
            ServerAddress.normalize(input, 8766);
            throw new AssertionError("Expected rejection for: " + input);
        } catch (IllegalArgumentException expected) {
            // Expected invalid input.
        }
    }
}
