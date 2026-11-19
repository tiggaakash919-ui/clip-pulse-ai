package com.clippulse.app;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.DownloadManager;
import android.app.ProgressDialog;
import android.content.ActivityNotFoundException;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.view.View;
import android.text.InputType;
import android.webkit.ConsoleMessage;
import android.webkit.CookieManager;
import android.webkit.DownloadListener;
import android.webkit.URLUtil;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebResourceResponse;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import java.net.HttpURLConnection;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.URI;
import java.net.URL;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

public class MainActivity extends Activity {

    private static final String PREFS_NAME = "ClipPulsePrefs";
    private static final String KEY_SERVER_URL = "server_url";
    private static final String LOCAL_SERVER_URL = "http://127.0.0.1:8766/app";
    private static final String HOTSPOT_SERVER_URL = "http://192.168.43.1:8766/app";
    private static final int SERVER_PORT = 8766;

    private WebView mWebView;
    private ProgressBar mProgressBar;
    private View mStatusIndicator;
    private View mErrorLayout;
    private TextView mTvErrorMessage;
    private TextView mTvRetryCountdown;
    private Button mBtnRefresh;
    private Button mBtnServer;
    private Button mBtnRetry;
    private Button mBtnCopyCmd;
    private Button mBtnGuide;
    private Button mBtnHotspot;
    private Button mBtnScanNetwork;
    private Button mBtnEnterIp;

    private SharedPreferences mPrefs;
    private String mCurrentUrl;
    private ValueCallback<Uri[]> mFileChooserCallback;
    private static final int FILE_CHOOSER_REQUEST = 4102;

    private Handler mRetryHandler = new Handler();
    private int mCountdownSeconds = 3;

    private final Runnable mRetryRunnable = new Runnable() {
        @Override
        public void run() {
            if (mErrorLayout != null && mErrorLayout.getVisibility() == View.VISIBLE) {
                if (mCountdownSeconds > 1) {
                    mCountdownSeconds--;
                    mTvRetryCountdown.setText("Auto-reconnecting in " + mCountdownSeconds + "s...");
                    mRetryHandler.postDelayed(this, 1000);
                } else {
                    mTvRetryCountdown.setText("Reconnecting...");
                    mCountdownSeconds = 3;
                    loadUrl(mCurrentUrl);
                    mRetryHandler.postDelayed(this, 3000);
                }
            }
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mPrefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        mCurrentUrl = mPrefs.getString(KEY_SERVER_URL, "");

        mWebView = findViewById(R.id.webView);
        mProgressBar = findViewById(R.id.progressBar);
        mStatusIndicator = findViewById(R.id.statusIndicator);
        mErrorLayout = findViewById(R.id.errorLayout);
        mTvErrorMessage = findViewById(R.id.tvErrorMessage);
        mTvRetryCountdown = findViewById(R.id.tvRetryCountdown);
        mBtnRefresh = findViewById(R.id.btnRefresh);
        mBtnServer = findViewById(R.id.btnServer);
        mBtnRetry = findViewById(R.id.btnRetry);
        mBtnCopyCmd = findViewById(R.id.btnCopyCmd);
        mBtnGuide = findViewById(R.id.btnGuide);
        mBtnHotspot = findViewById(R.id.btnHotspot);
        mBtnScanNetwork = findViewById(R.id.btnScanNetwork);
        mBtnEnterIp = findViewById(R.id.btnEnterIp);

        setupButtons();
        setupWebView();
        if (mCurrentUrl == null || mCurrentUrl.trim().isEmpty()) {
            mWebView.setVisibility(View.GONE);
            mErrorLayout.setVisibility(View.VISIBLE);
            mTvErrorMessage.setText("Paste your running Clip Pulse AI server’s HTTPS URL in Server settings to start. The app and engine are free; you host the engine yourself.");
            mTvRetryCountdown.setText("Ready when your server is online");
            showServerDialog();
        } else {
            loadUrl(mCurrentUrl);
        }
    }

    private void setStatusColor(String hexColor) {
        if (mStatusIndicator.getBackground() instanceof GradientDrawable) {
            ((GradientDrawable) mStatusIndicator.getBackground()).setColor(Color.parseColor(hexColor));
        }
    }

    private void setupButtons() {
        mBtnRefresh.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mWebView != null) {
                    mWebView.reload();
                }
            }
        });

        mBtnRetry.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mCurrentUrl = LOCAL_SERVER_URL;
                mPrefs.edit().putString(KEY_SERVER_URL, mCurrentUrl).apply();
                mTvRetryCountdown.setText("Connecting local...");
                loadUrl(mCurrentUrl);
            }
        });

        mBtnHotspot.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                connectHotspot();
            }
        });

        mBtnScanNetwork.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                scanLocalNetwork();
            }
        });

        mBtnEnterIp.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showServerDialog();
            }
        });

        mBtnCopyCmd.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                copyCommandToClipboard();
            }
        });

        mBtnGuide.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showGuideDialog();
            }
        });

        mBtnServer.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showServerDialog();
            }
        });
    }

    private void connectHotspot() {
        mCurrentUrl = HOTSPOT_SERVER_URL;
        mPrefs.edit().putString(KEY_SERVER_URL, mCurrentUrl).apply();
        Toast.makeText(this, "Connecting via Hotspot (192.168.43.1)...", Toast.LENGTH_SHORT).show();
        loadUrl(mCurrentUrl);
    }

    private void copyCommandToClipboard() {
        String cmd = "cd ~/ClipPulse 2>/dev/null || cd ~/PeakCut; bash scripts/termux/run_all_24_7.sh";
        ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
        if (clipboard != null) {
            ClipData clip = ClipData.newPlainText("Clip Pulse AI Command", cmd);
            clipboard.setPrimaryClip(clip);
            Toast.makeText(this, "Command copied! Termux me paste karein.", Toast.LENGTH_SHORT).show();
        }
    }

    private void showGuideDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Clip Pulse AI 24/7 Setup Guide");
        builder.setMessage(
            "Clip Pulse AI 24/7 bina aapke on kiye khud chalega:\n\n" +
            "1. Phone Boot Auto-Start:\n" +
            "   Phone switch on / reboot hote hi Termux background me Clip Pulse AI engine aur online link khud start kar deta hai.\n\n" +
            "2. Battery Optimization (Unrestricted):\n" +
            "   Android Settings -> Apps -> Termux -> Battery -> 'Unrestricted' select karein taaki Android CPU ko na roke.\n\n" +
            "3. Termux Lock in Recent Apps:\n" +
            "   Recent apps screen me Termux par long-press karke lock (padlock) icon daba dein taaki clear-all se Termux close na ho.\n\n" +
            "4. Online Link:\n" +
            "   Aapka latest online link hamesha phone ke Download folder me 'clippulse_online_url.txt' me save hota rehta hai."
        );
        builder.setPositiveButton("OK", null);
        builder.setNeutralButton("Copy Command", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                copyCommandToClipboard();
            }
        });
        builder.show();
    }

    private void showServerDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Connect to your Clip Pulse AI server");
        builder.setMessage("Paste the HTTPS address of your running Clip Pulse AI server. The free engine runs on your own computer, phone or server.");

        final EditText input = new EditText(this);
        input.setText(mCurrentUrl);
        input.setHint("https://your-domain.com");
        input.setSingleLine(true);
        input.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_URI);
        input.setSelection(input.length());
        input.setTextColor(Color.WHITE);
        builder.setView(input);

        builder.setPositiveButton("Connect", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                String newUrl;
                try {
                    newUrl = ServerAddress.normalize(input.getText().toString(), SERVER_PORT);
                } catch (IllegalArgumentException e) {
                    Toast.makeText(MainActivity.this, e.getMessage(), Toast.LENGTH_LONG).show();
                    return;
                }
                mCurrentUrl = newUrl;
                mPrefs.edit().putString(KEY_SERVER_URL, mCurrentUrl).apply();
                loadUrl(mCurrentUrl);
            }
        });

        builder.setNeutralButton("Hotspot (192.168.43.1)", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                connectHotspot();
            }
        });

        builder.setNegativeButton("Localhost", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                mCurrentUrl = LOCAL_SERVER_URL;
                mPrefs.edit().putString(KEY_SERVER_URL, mCurrentUrl).apply();
                loadUrl(mCurrentUrl);
            }
        });

        builder.show();
    }

    private boolean testServer(String ip) {
        HttpURLConnection conn = null;
        try {
            URL url = new URL("http://" + ip + ":8766/api/system/preflight");
            conn = (HttpURLConnection) url.openConnection();
            conn.setConnectTimeout(800);
            conn.setReadTimeout(800);
            conn.setRequestMethod("GET");
            return conn.getResponseCode() == 200;
        } catch (Exception ignored) {
        } finally {
            if (conn != null) {
                try { conn.disconnect(); } catch (Exception ignored) {}
            }
        }
        return false;
    }

    private List<String> getLocalSubnets() {
        List<String> list = new ArrayList<>();
        list.add("192.168.43."); // Hotspot subnet
        try {
            Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
            while (interfaces != null && interfaces.hasMoreElements()) {
                NetworkInterface ni = interfaces.nextElement();
                if (ni.isLoopback() || !ni.isUp()) continue;
                Enumeration<InetAddress> addresses = ni.getInetAddresses();
                while (addresses.hasMoreElements()) {
                    InetAddress addr = addresses.nextElement();
                    if (!addr.isLoopbackAddress() && addr instanceof Inet4Address) {
                        String ip = addr.getHostAddress();
                        if (ip != null && (ip.startsWith("192.168.") || ip.startsWith("10.") || ip.startsWith("172."))) {
                            String prefix = ip.substring(0, ip.lastIndexOf('.') + 1);
                            if (!list.contains(prefix)) {
                                list.add(0, prefix);
                            }
                        }
                    }
                }
            }
        } catch (Exception ignored) {}
        return list;
    }

    private String scanSubnet(final String prefix) {
        ExecutorService executor = Executors.newFixedThreadPool(25);
        final AtomicReference<String> found = new AtomicReference<>(null);

        for (int i = 1; i <= 254; i++) {
            final String testIp = prefix + i;
            executor.submit(new Runnable() {
                @Override
                public void run() {
                    if (found.get() != null) return;
                    if (testServer(testIp)) {
                        found.compareAndSet(null, testIp);
                    }
                }
            });
        }

        executor.shutdown();
        try {
            executor.awaitTermination(3500, TimeUnit.MILLISECONDS);
        } catch (InterruptedException ignored) {}
        executor.shutdownNow();

        return found.get();
    }

    private void scanLocalNetwork() {
        final ProgressDialog progress = new ProgressDialog(this);
        progress.setTitle("Scanning Local Network");
        progress.setMessage("Searching for Clip Pulse AI on Wi-Fi / Hotspot...");
        progress.setCancelable(false);
        progress.show();

        new Thread(new Runnable() {
            @Override
            public void run() {
                String foundIp = null;
                // Fast check hotspot first
                if (testServer("192.168.43.1")) {
                    foundIp = "192.168.43.1";
                }

                // If not found, scan active subnets
                if (foundIp == null) {
                    List<String> subnets = getLocalSubnets();
                    for (String subnet : subnets) {
                        foundIp = scanSubnet(subnet);
                        if (foundIp != null) break;
                    }
                }

                final String finalFoundIp = foundIp;
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        try { progress.dismiss(); } catch (Exception ignored) {}
                        if (finalFoundIp != null) {
                            Toast.makeText(MainActivity.this, "Found Clip Pulse AI on " + finalFoundIp + "! Connecting...", Toast.LENGTH_LONG).show();
                            mCurrentUrl = "http://" + finalFoundIp + ":8766/app";
                            mPrefs.edit().putString(KEY_SERVER_URL, mCurrentUrl).apply();
                            loadUrl(mCurrentUrl);
                        } else {
                            showScanFailedDialog();
                        }
                    }
                });
            }
        }).start();
    }

    private void showScanFailedDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Clip Pulse AI Server Nahi Mila");
        builder.setMessage(
            "Local network par koi Clip Pulse AI server nahi mila.\n\n" +
            "Kripya check karein:\n" +
            "1. Phone 1 par Termux server chal raha hai.\n" +
            "2. Dono phones ek hi Wi-Fi se jude hain YA Phone 1 ka Hotspot on karke is phone ko usse connect karein.\n\n" +
            "Agar Hotspot connect kiya hai to 'Hotspot Try Karein' par tap karein."
        );
        builder.setPositiveButton("Enter IP Manually", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                showServerDialog();
            }
        });
        builder.setNeutralButton("Hotspot Try Karein", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                connectHotspot();
            }
        });
        builder.setNegativeButton("Cancel", null);
        builder.show();
    }

    private void setupWebView() {
        WebSettings settings = mWebView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setDatabaseEnabled(true);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
        settings.setUseWideViewPort(true);
        settings.setLoadWithOverviewMode(true);
        settings.setSupportZoom(false);
        settings.setMediaPlaybackRequiresUserGesture(false);

        CookieManager.getInstance().setAcceptCookie(true);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            CookieManager.getInstance().setAcceptThirdPartyCookies(mWebView, true);
        }

        mWebView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onProgressChanged(WebView view, int newProgress) {
                if (newProgress < 100) {
                    mProgressBar.setVisibility(View.VISIBLE);
                    mProgressBar.setProgress(newProgress);
                } else {
                    mProgressBar.setVisibility(View.GONE);
                }
            }

            @Override
            public boolean onConsoleMessage(ConsoleMessage consoleMessage) {
                return super.onConsoleMessage(consoleMessage);
            }

            @Override
            public boolean onShowFileChooser(WebView webView, ValueCallback<Uri[]> filePathCallback,
                                             FileChooserParams fileChooserParams) {
                if (mFileChooserCallback != null) {
                    mFileChooserCallback.onReceiveValue(null);
                }
                mFileChooserCallback = filePathCallback;
                try {
                    Intent intent = fileChooserParams.createIntent();
                    startActivityForResult(intent, FILE_CHOOSER_REQUEST);
                    return true;
                } catch (ActivityNotFoundException | SecurityException e) {
                    mFileChooserCallback = null;
                    filePathCallback.onReceiveValue(null);
                    Toast.makeText(MainActivity.this, "No file picker is available on this device.", Toast.LENGTH_LONG).show();
                    return false;
                }
            }
        });

        mWebView.setWebViewClient(new WebViewClient() {
            private boolean isAllowedPage(String url) {
                try {
                    URI target = new URI(url);
                    URI server = new URI(mCurrentUrl);
                    int targetPort = target.getPort() == -1 ? ("https".equalsIgnoreCase(target.getScheme()) ? 443 : 80) : target.getPort();
                    int serverPort = server.getPort() == -1 ? ("https".equalsIgnoreCase(server.getScheme()) ? 443 : 80) : server.getPort();
                    return target.getHost() != null && server.getHost() != null
                            && target.getHost().equalsIgnoreCase(server.getHost()) && targetPort == serverPort
                            && target.getScheme() != null && target.getScheme().matches("(?i)https?");
                } catch (Exception e) {
                    return false;
                }
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                Uri uri = request.getUrl();
                String target = uri == null ? "" : uri.toString();
                if (isAllowedPage(target)) return false;
                try {
                    Intent intent = new Intent(Intent.ACTION_VIEW, uri);
                    startActivity(intent);
                } catch (ActivityNotFoundException ignored) {}
                return true;
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                if (isAllowedPage(url)) return false;
                try {
                    startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url)));
                } catch (Exception ignored) {}
                return true;
            }

            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                if (url != null && !url.equals("about:blank")) {
                    setStatusColor("#FF8B33"); // Pending
                }
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                if (url != null && !url.equals("about:blank") && !url.startsWith("data:")) {
                    setStatusColor("#0F8A57"); // Connected / Good
                    mErrorLayout.setVisibility(View.GONE);
                    mWebView.setVisibility(View.VISIBLE);
                    if (mRetryHandler != null && mRetryRunnable != null) {
                        mRetryHandler.removeCallbacks(mRetryRunnable);
                    }
                }
            }

            @Override
            public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
                if (request != null && request.isForMainFrame()) {
                    showError("Failed to reach: " + mCurrentUrl + "\n\nServer connect nahi hua (ERR_CONNECTION_REFUSED).");
                }
            }

            @Override
            public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
                if (failingUrl != null && !failingUrl.equals("about:blank")) {
                    showError("Connection failed to: " + failingUrl + "\n\n" + description);
                }
            }

            @Override
            public void onReceivedHttpError(WebView view, WebResourceRequest request, WebResourceResponse response) {
                if (request != null && request.isForMainFrame() && response != null && response.getStatusCode() >= 400) {
                    showError("Clip Pulse AI server returned " + response.getStatusCode() + ". Check the server URL and sign-in details.");
                }
            }
        });

        mWebView.setDownloadListener(new DownloadListener() {
            @Override
            public void onDownloadStart(String url, String userAgent, String contentDisposition, String mimeType, long contentLength) {
                try {
                    DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));
                    request.setMimeType(mimeType);
                    String cookie = CookieManager.getInstance().getCookie(url);
                    if (cookie != null && !cookie.isEmpty()) {
                        request.addRequestHeader("Cookie", cookie);
                    }
                    if (userAgent != null && !userAgent.isEmpty()) {
                        request.addRequestHeader("User-Agent", userAgent);
                    }
                    String fileName = URLUtil.guessFileName(url, contentDisposition, mimeType);
                    request.setTitle(fileName);
                    request.setDescription("Downloading Clip Pulse AI clip...");
                    request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
                    request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName);

                    DownloadManager dm = (DownloadManager) getSystemService(Context.DOWNLOAD_SERVICE);
                    if (dm != null) {
                        dm.enqueue(request);
                        Toast.makeText(MainActivity.this, "Downloading clip to Downloads: " + fileName, Toast.LENGTH_SHORT).show();
                    }
                } catch (Exception e) {
                    Toast.makeText(MainActivity.this, "Download error: " + e.getMessage(), Toast.LENGTH_LONG).show();
                }
            }
        });
    }

    private void loadUrl(String url) {
        if (url == null || url.trim().isEmpty()) {
            url = LOCAL_SERVER_URL;
        }
        mCurrentUrl = url.trim();
        mWebView.loadUrl(mCurrentUrl);
    }

    private void showError(String message) {
        setStatusColor("#D3343F"); // Offline / Bad
        mWebView.stopLoading();
        mWebView.loadUrl("about:blank");
        mWebView.setVisibility(View.GONE);
        mErrorLayout.setVisibility(View.VISIBLE);
        mTvErrorMessage.setText(message);

        mCountdownSeconds = 3;
        mTvRetryCountdown.setText("Auto-reconnecting in 3s...");
        if (mRetryHandler != null && mRetryRunnable != null) {
            mRetryHandler.removeCallbacks(mRetryRunnable);
            mRetryHandler.postDelayed(mRetryRunnable, 1000);
        }

        // If local 127.0.0.1 failed, auto-probe hotspot gateway (192.168.43.1) in background!
        if (mCurrentUrl.contains("127.0.0.1")) {
            new Thread(new Runnable() {
                @Override
                public void run() {
                    if (testServer("192.168.43.1")) {
                        runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                Toast.makeText(MainActivity.this, "Phone 1 Hotspot detected! Connecting...", Toast.LENGTH_SHORT).show();
                                connectHotspot();
                            }
                        });
                    }
                }
            }).start();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == FILE_CHOOSER_REQUEST) {
            if (mFileChooserCallback != null) {
                Uri[] results = null;
                if (resultCode == RESULT_OK && data != null) {
                    if (data.getClipData() != null) {
                        int count = data.getClipData().getItemCount();
                        results = new Uri[count];
                        for (int i = 0; i < count; i++) {
                            results[i] = data.getClipData().getItemAt(i).getUri();
                        }
                    } else if (data.getData() != null) {
                        results = new Uri[]{data.getData()};
                    }
                }
                mFileChooserCallback.onReceiveValue(results);
                mFileChooserCallback = null;
            }
            return;
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    protected void onDestroy() {
        if (mFileChooserCallback != null) {
            mFileChooserCallback.onReceiveValue(null);
            mFileChooserCallback = null;
        }
        if (mRetryHandler != null && mRetryRunnable != null) {
            mRetryHandler.removeCallbacks(mRetryRunnable);
        }
        super.onDestroy();
    }

    @Override
    public void onBackPressed() {
        if (mWebView != null && mWebView.canGoBack()) {
            mWebView.goBack();
        } else {
            super.onBackPressed();
        }
    }
}
