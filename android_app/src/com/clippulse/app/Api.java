package com.clippulse.app;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

/** The small part of HTTP the native screens need. Nothing here talks to anything but the ClipPulse server. */
final class Api {
    private Api() {}

    static JSONObject getJson(String url) throws Exception {
        return new JSONObject(request("GET", url, null));
    }

    static String get(String url) throws Exception {
        return request("GET", url, null);
    }

    static String post(String url, String body) throws Exception {
        return request("POST", url, body);
    }

    private static String request(String method, String address, String body) throws Exception {
        HttpURLConnection c = (HttpURLConnection) new URL(address).openConnection();
        try {
            c.setRequestMethod(method);
            c.setConnectTimeout(6000);
            c.setReadTimeout(90000);
            c.setRequestProperty("Accept", "application/json");
            c.setRequestProperty("User-Agent", "ClipPulseAI-Android");
            if (body != null) {
                c.setDoOutput(true);
                c.setRequestProperty("Content-Type", "application/json; charset=utf-8");
                byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
                c.setFixedLengthStreamingMode(bytes.length);
                try (OutputStream out = c.getOutputStream()) {
                    out.write(bytes);
                }
            }
            int code = c.getResponseCode();
            String text = read(code >= 400 ? c.getErrorStream() : c.getInputStream());
            if (code >= 400) {
                String detail = text;
                try {
                    detail = new JSONObject(text).optString("detail", text);
                } catch (Exception ignored) {
                    // not JSON: show the plain answer
                }
                throw new IOException(detail.isEmpty() ? "Server answered " + code : detail);
            }
            return text;
        } finally {
            c.disconnect();
        }
    }

    private static String read(InputStream in) throws IOException {
        if (in == null) return "";
        StringBuilder out = new StringBuilder();
        try (BufferedReader r = new BufferedReader(new InputStreamReader(in, StandardCharsets.UTF_8))) {
            char[] buf = new char[4096];
            int n;
            while ((n = r.read(buf)) > 0) out.append(buf, 0, n);
        }
        return out.toString();
    }

    /** The server address without the /app page, e.g. http://127.0.0.1:8766 */
    static String base(String serverUrl) {
        String value = serverUrl == null ? "" : serverUrl.trim();
        while (value.endsWith("/")) value = value.substring(0, value.length() - 1);
        if (value.endsWith("/app")) value = value.substring(0, value.length() - 4);
        if (value.isEmpty()) value = "http://127.0.0.1:8766";
        if (!value.matches("(?i)^https?://.*")) value = "http://" + value;
        return value;
    }
}
