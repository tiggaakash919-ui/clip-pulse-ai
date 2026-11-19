package com.clippulse.app;

import java.net.URI;
import java.net.URISyntaxException;

/** Normalizes the server address entered in the Android app. */
final class ServerAddress {
    private ServerAddress() {}

    static String normalize(String value, int localPort) {
        String text = value == null ? "" : value.trim();
        if (text.isEmpty()) {
            throw new IllegalArgumentException("Enter your Clip Pulse AI server address first.");
        }
        if (text.matches("(?i)^[a-z][a-z0-9+.-]*://.*") && !text.matches("(?i)^https?://.*")) {
            throw new IllegalArgumentException("Use a valid server URL, such as https://your-domain.com.");
        }
        if (!text.matches("(?i)^https?://.*")) {
            text = isLocalHost(text)
                    ? "http://" + text : "https://" + text;
        }
        try {
            URI parsed = new URI(text);
            String scheme = parsed.getScheme() == null ? "" : parsed.getScheme().toLowerCase();
            String host = parsed.getHost();
            if (!("http".equals(scheme) || "https".equals(scheme)) || host == null || host.isEmpty()
                    || parsed.getUserInfo() != null || parsed.getQuery() != null || parsed.getFragment() != null) {
                throw new IllegalArgumentException("Use a valid server URL, such as https://your-domain.com.");
            }
            int port = parsed.getPort();
            if (port < -1 || port == 0 || port > 65535) {
                throw new IllegalArgumentException("The server port must be between 1 and 65535.");
            }
            if (port == -1 && "http".equals(scheme) && isLocalHost(host)) {
                port = localPort;
            }
            String path = parsed.getPath() == null ? "" : parsed.getPath().replaceAll("/+$", "");
            if (!path.endsWith("/app")) {
                path += "/app";
            }
            return new URI(scheme, null, host, port, path, null, null).toASCIIString();
        } catch (URISyntaxException e) {
            throw new IllegalArgumentException("Use a valid server URL, such as https://your-domain.com.");
        }
    }

    private static boolean isLocalHost(String host) {
        String value = host == null ? "" : host.toLowerCase();
        return "localhost".equals(value) || value.startsWith("127.") || value.startsWith("10.")
                || value.startsWith("192.168.") || value.matches("172\\.(1[6-9]|2[0-9]|3[01])\\..*");
    }
}
