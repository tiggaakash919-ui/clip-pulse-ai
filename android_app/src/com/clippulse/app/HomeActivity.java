package com.clippulse.app;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/** The native home screen: engine status, a link to clip, and the latest jobs. */
public class HomeActivity extends Activity {
    static final String PREFS = "ClipPulsePrefs";
    static final String KEY_SERVER_URL = "server_url";
    static final String KEY_AUTO_START = "auto_start_engine_on_open";
    static final String DEFAULT_SERVER = "http://127.0.0.1:8766/app";

    private final ExecutorService io = Executors.newSingleThreadExecutor();
    private final Handler ui = new Handler(Looper.getMainLooper());

    private SharedPreferences prefs;
    private View statusDot;
    private TextView engineTitle, engineDetail, jobsEmpty, newStatus, setupHint;
    private android.widget.Switch autoToggle;
    private LinearLayout jobsBox;
    private EditText urlInput;
    private Button makeButton;
    private boolean autoTried;
    private boolean toastShown;
    private boolean running;
    private volatile boolean engineOnline;

    private final Runnable refreshLoop = new Runnable() {
        @Override
        public void run() {
            if (!running) return;
            checkHealth(false);
            loadJobs();
            ui.postDelayed(this, 5000);
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        setContentView(build());
        autoTried = false;                 // app open karne par engine kaam karna hai
        toastShown = false;
        refreshAll(true);
    }

    @Override
    protected void onResume() {
        super.onResume();
        running = true;
        ui.removeCallbacks(refreshLoop);
        ui.post(refreshLoop);
    }

    @Override
    protected void onPause() {
        running = false;
        ui.removeCallbacks(refreshLoop);
        super.onPause();
    }

    private String serverUrl() {
        return prefs.getString(KEY_SERVER_URL, DEFAULT_SERVER);
    }

    private String base() {
        return Api.base(serverUrl());
    }

    private View build() {
        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(Ui.color(this, R.color.frame));
        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(Ui.dp(this, 16), Ui.dp(this, 18), Ui.dp(this, 16), Ui.dp(this, 24));
        scroll.addView(content);

        LinearLayout header = Ui.row(this);
        TextView name = Ui.text(this, "ClipPulse AI", 26, Ui.color(this, R.color.brand), true);
        header.addView(name, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1));
        statusDot = Ui.dot(this, Ui.color(this, R.color.status_pending));
        header.addView(statusDot);
        Button settings = Ui.button(this, "Server", false);
        settings.setOnClickListener(v -> showServerDialog());
        LinearLayout.LayoutParams sp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, Ui.dp(this, 40));
        header.addView(settings, sp);
        content.addView(header);

        TextView sub = Ui.text(this, "Native dashboard. Engine phone ke andar Termux me chalta hai.",
                13, Ui.color(this, R.color.text_secondary), false);
        sub.setPadding(0, Ui.dp(this, 2), 0, Ui.dp(this, 14));
        content.addView(sub);

        // ---- engine
        LinearLayout engine = Ui.card(this);
        LinearLayout engineHead = Ui.row(this);
        engineHead.addView(Ui.text(this, "ENGINE", 11, Ui.color(this, R.color.text_secondary), true),
                new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1));
        TextView how = Ui.text(this, "Kaise chalta hai?", 12, Ui.color(this, R.color.brand), false);
        how.setOnClickListener(v -> showEngineInfo());
        engineHead.addView(how);
        engine.addView(engineHead);
        engineTitle = Ui.text(this, "Checking...", 20, Ui.color(this, R.color.text_primary), true);
        engine.addView(engineTitle);
        engineDetail = Ui.text(this, "", 13, Ui.color(this, R.color.text_secondary), false);
        engineDetail.setPadding(0, Ui.dp(this, 4), 0, Ui.dp(this, 12));
        engine.addView(engineDetail);

        LinearLayout engineButtons = Ui.row(this);
        Button start = Ui.button(this, "Start engine", true);
        start.setOnClickListener(v -> startEngine());
        engineButtons.addView(start, new LinearLayout.LayoutParams(0, Ui.dp(this, 46), 1));
        Ui.gap(this, engineButtons, 8);
        Button editor = Ui.button(this, "Full editor", false);
        editor.setOnClickListener(v -> openEditor());
        engineButtons.addView(editor, new LinearLayout.LayoutParams(0, Ui.dp(this, 46), 1));
        engine.addView(engineButtons);

        LinearLayout autoRow = Ui.row(this);
        autoToggle = new android.widget.Switch(this);
        autoToggle.setChecked(prefs.getBoolean(KEY_AUTO_START, true));
        autoToggle.setText("Engine kholne se start");
        autoToggle.setTextSize(13);
        autoToggle.setTextColor(Ui.color(this, R.color.text_secondary));
        autoToggle.setOnCheckedChangeListener((b, isChecked) -> {
            prefs.edit().putBoolean(KEY_AUTO_START, isChecked).apply();
            if (isChecked && !engineOnline) startEngine();
        });
        autoRow.addView(autoToggle, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, Ui.dp(this, 42)));
        engine.addView(autoRow);

        setupHint = Ui.text(this, ServerStarter.canCommand(this)
                        ? "Engine band ho jaye to Start engine dabayein: app khud Termux me chala deta hai."
                        : "Is Termux build me app se command nahi chalti. Yahan tap karein: command copy hoga aur "
                          + "Termux khulega — ek baar paste karke Enter dabayein. Uske baad engine chalta rehta hai.",
                12, Ui.color(this, R.color.text_secondary), false);
        setupHint.setPadding(0, Ui.dp(this, 10), 0, 0);
        setupHint.setOnClickListener(v -> copySetupCommand());
        engine.addView(setupHint);
        content.addView(engine);

        // ---- new clip
        LinearLayout create = Ui.card(this);
        create.addView(Ui.text(this, "NEW CLIP", 11, Ui.color(this, R.color.text_secondary), true));
        create.addView(Ui.text(this, "Paste a YouTube, Twitch or Kick link", 18,
                Ui.color(this, R.color.text_primary), true));
        urlInput = new EditText(this);
        urlInput.setHint("https://youtube.com/watch?v=...");
        urlInput.setSingleLine(true);
        urlInput.setTextColor(Ui.color(this, R.color.text_primary));
        urlInput.setHintTextColor(Ui.color(this, R.color.text_secondary));
        urlInput.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_URI);
        LinearLayout.LayoutParams ip = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        ip.topMargin = Ui.dp(this, 10);
        ip.bottomMargin = Ui.dp(this, 8);
        create.addView(urlInput, ip);
        makeButton = Ui.button(this, "Make clips", true);
        makeButton.setOnClickListener(v -> makeClips());
        create.addView(makeButton, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, Ui.dp(this, 48)));
        newStatus = Ui.text(this, "", 13, Ui.color(this, R.color.text_secondary), false);
        newStatus.setPadding(0, Ui.dp(this, 8), 0, 0);
        create.addView(newStatus);
        content.addView(create);

        // ---- jobs
        LinearLayout jobs = Ui.card(this);
        LinearLayout jobsHead = Ui.row(this);
        jobsHead.addView(Ui.text(this, "RECENT CLIPS", 11, Ui.color(this, R.color.text_secondary), true),
                new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1));
        Button refresh = Ui.button(this, "Refresh", false);
        refresh.setOnClickListener(v -> refreshAll(false));
        jobsHead.addView(refresh, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, Ui.dp(this, 38)));
        jobs.addView(jobsHead);
        jobsEmpty = Ui.text(this, "Abhi koi clip nahi. Upar link paste karke Make clips dabayein.",
                13, Ui.color(this, R.color.text_secondary), false);
        jobsEmpty.setPadding(0, Ui.dp(this, 12), 0, Ui.dp(this, 4));
        jobs.addView(jobsEmpty);
        jobsBox = new LinearLayout(this);
        jobsBox.setOrientation(LinearLayout.VERTICAL);
        jobs.addView(jobsBox);
        content.addView(jobs);

        TextView footer = Ui.text(this, "Free and open source. Your videos stay on your phone or server.",
                11, Ui.color(this, R.color.text_secondary), false);
        footer.setGravity(Gravity.CENTER);
        footer.setPadding(0, Ui.dp(this, 8), 0, 0);
        content.addView(footer);
        return scroll;
    }

    private void refreshAll(boolean maybeStart) {
        checkHealth(maybeStart);
        loadJobs();
    }

    private void checkHealth(boolean maybeStart) {
        io.execute(() -> {
            boolean ok;
            String detail = "";
            try {
                Api.get(base() + "/healthz");
                ok = true;
            } catch (Exception e) {
                ok = false;
                detail = e.getMessage() == null ? "Engine offline" : e.getMessage();
            }
            final boolean online = ok;
            final String why = detail;
            ui.post(() -> {
                engineOnline = online;
                setStatus(online);
                if (online) {
                    autoTried = true;
                    engineTitle.setText("Engine online");
                    engineDetail.setText("Ready to make clips.");
                } else {
                    engineTitle.setText("Engine offline");
                    engineDetail.setText("Start engine dabayein, ya Server se doosra address set karein.");
                    if (maybeStart && !autoTried && prefs.getBoolean(KEY_AUTO_START, true)) {
                        autoTried = true;
                        startEngine();
                    }
                }
            });
        });
    }

    private void setStatus(boolean online) {
        statusDot.setBackgroundResource(0);
        statusDot.setBackground(new android.graphics.drawable.GradientDrawable() {{
            setShape(android.graphics.drawable.GradientDrawable.OVAL);
            setColor(Ui.color(HomeActivity.this,
                    online ? R.color.status_good : R.color.status_bad));
        }});
    }

    private void startEngine() {
        if (engineOnline) {
            engineTitle.setText("Engine online");
            engineDetail.setText("Ready to make clips.");
            return;
        }
        if (!ServerStarter.installed(this)) {
            engineTitle.setText("Remote engine recommend karein");
            engineDetail.setText("Aapke phone me Termux nahi hai, isliye engine chal nahi sakta. " +
                    "Server phone change karne ko Server button dhire — CMP, ya remote karein.");
            return;
        }
        engineTitle.setText("Engine start ho raha hai...");
        engineDetail.setText("Termux me ClipPulse server khul raha hai. 10-20 second lag sakte hain.");
        boolean sent = ServerStarter.start(this);
        if (!sent) {
            engineDetail.setText("Command copy ho gaya aur Termux khul gaya. Wahan paste karke Enter dabayein — "
                    + "phir engine chalta rahega.");
            setupHint.setTextColor(Ui.color(this, R.color.brand));
        }
        ui.postDelayed(() -> checkHealth(false), 8000);
        ui.postDelayed(() -> checkHealth(false), 18000);
    }

    private void showEngineInfo() {
        new AlertDialog.Builder(this)
                .setTitle("Engine kaise chalta hai")
                .setMessage(ServerStarter.explanation(this))
                .setPositiveButton("Samajh gaya", null)
                .setNeutralButton("Command copy", (d, w) -> copySetupCommand())
                .show();
    }

    private void openEditor() {
        Intent intent = new Intent(this, MainActivity.class);
        startActivity(intent);
    }

    private void copySetupCommand() {
        ServerStarter.copyStartCommand(this);
        ServerStarter.openTermux(this);
    }

    private void makeClips() {
        String url = urlInput.getText().toString().trim();
        if (!url.matches("(?i)^https?://.*")) {
            newStatus.setText("Poora link paste karein (https:// se shuru).");
            newStatus.setTextColor(Ui.color(this, R.color.status_bad));
            return;
        }
        makeButton.setEnabled(false);
        makeButton.setText("Bhej raha hoon...");
        newStatus.setTextColor(Ui.color(this, R.color.text_secondary));
        newStatus.setText("Video server ko bheji ja rahi hai...");
        io.execute(() -> {
            try {
                JSONObject options = new JSONObject();
                options.put("max_clips", 6);
                options.put("min_len", 15);
                options.put("max_len", 60);
                JSONObject body = new JSONObject();
                body.put("url", url);
                body.put("options", options);
                Api.post(base() + "/api/jobs", body.toString());
                ui.post(() -> {
                    makeButton.setEnabled(true);
                    makeButton.setText("Make clips");
                    urlInput.setText("");
                    newStatus.setTextColor(Ui.color(this, R.color.status_good));
                    newStatus.setText("Video queue mein aa gayi. Neeche progress dekhein.");
                    loadJobs();
                });
            } catch (Exception e) {
                ui.post(() -> {
                    makeButton.setEnabled(true);
                    makeButton.setText("Make clips");
                    newStatus.setTextColor(Ui.color(this, R.color.status_bad));
                    newStatus.setText(e.getMessage() == null ? "Server se baat nahi ho paayi." : e.getMessage());
                });
            }
        });
    }

    private void loadJobs() {
        io.execute(() -> {
            try {
                String text = Api.get(base() + "/api/jobs");
                JSONArray list = new JSONArray(text);
                ui.post(() -> showJobs(list));
            } catch (Exception ignored) {
                // the engine is offline; the status card already says so
            }
        });
    }

    private void showJobs(JSONArray list) {
        jobsBox.removeAllViews();
        jobsEmpty.setVisibility(list.length() == 0 ? View.VISIBLE : View.GONE);
        for (int i = 0; i < list.length() && i < 8; i++) {
            JSONObject job = list.optJSONObject(i);
            if (job == null) continue;
            jobsBox.addView(jobRow(job));
        }
    }

    private View jobRow(JSONObject job) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.VERTICAL);
        row.setPadding(0, Ui.dp(this, 10), 0, Ui.dp(this, 10));
        row.setBackgroundResource(R.drawable.card_bg);
        LinearLayout.LayoutParams rp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        rp.bottomMargin = Ui.dp(this, 8);
        row.setLayoutParams(rp);

        String title = job.optString("title", "");
        if (title.isEmpty()) {
            JSONObject source = job.optJSONObject("source");
            title = source == null ? "Video" : source.optString("url", "Video");
        }
        row.addView(Ui.text(this, title, 15, Ui.color(this, R.color.text_primary), true));
        String status = job.optString("status", "");
        String stage = job.optString("stage", "");
        int pct = (int) Math.round(job.optDouble("progress", 0) * 100);
        String line = status.equals("done") ? "Done" : (stage.isEmpty() ? status : stage) + " · " + pct + "%";
        TextView meta = Ui.text(this, line, 12,
                Ui.color(this, status.equals("error") ? R.color.status_bad : R.color.text_secondary), false);
        meta.setPadding(0, Ui.dp(this, 3), 0, 0);
        row.addView(meta);
        row.setOnClickListener(v -> {
            Intent intent = new Intent(this, JobActivity.class);
            intent.putExtra("job_id", job.optString("id"));
            startActivity(intent);
        });
        return row;
    }

    private void showServerDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("ClipPulse server");
        final EditText input = new EditText(this);
        input.setText(serverUrl());
        input.setSingleLine(true);
        input.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_URI);
        input.setTextColor(Color.WHITE);
        builder.setView(input);
        builder.setPositiveButton("Save", (dialog, which) -> {
            String value = input.getText().toString().trim();
            if (!value.matches("(?i)^https?://.*")) value = "http://" + value;
            while (value.endsWith("/")) value = value.substring(0, value.length() - 1);
            if (value.endsWith("/app")) value = value.substring(0, value.length() - 4);
            prefs.edit().putString(KEY_SERVER_URL, value + "/app").apply();
            autoTried = false;
            refreshAll(false);
        });
        builder.setNegativeButton("Cancel", null);
        builder.setNeutralButton("Local", (dialog, which) -> {
            prefs.edit().putString(KEY_SERVER_URL, DEFAULT_SERVER).apply();
            autoTried = false;
            refreshAll(true);
        });
        builder.show();
    }
}
