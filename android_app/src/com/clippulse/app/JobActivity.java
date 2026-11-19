package com.clippulse.app;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/** One video's clips, kept up to date while the server works on it. */
public class JobActivity extends Activity {
    private final ExecutorService io = Executors.newSingleThreadExecutor();
    private final Handler ui = new Handler(Looper.getMainLooper());

    private String jobId;
    private String base;
    private TextView title, meta, error;
    private LinearLayout clipsBox;
    private LinearLayout progressRow;
    private boolean running = true;

    private final Runnable poll = new Runnable() {
        @Override
        public void run() {
            if (!running || jobId == null || jobId.isEmpty()) return;
            load();
            ui.postDelayed(this, 3000);
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        jobId = getIntent().getStringExtra("job_id");
        base = Api.base(getSharedPreferences(HomeActivity.PREFS, MODE_PRIVATE)
                .getString(HomeActivity.KEY_SERVER_URL, HomeActivity.DEFAULT_SERVER));
        setContentView(build());
        load();
    }

    @Override
    protected void onResume() {
        super.onResume();
        running = true;
        ui.removeCallbacks(poll);
        ui.postDelayed(poll, 3000);
    }

    @Override
    protected void onPause() {
        running = false;
        ui.removeCallbacks(poll);
        super.onPause();
    }

    private View build() {
        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(Ui.color(this, R.color.frame));
        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(Ui.dp(this, 16), Ui.dp(this, 18), Ui.dp(this, 16), Ui.dp(this, 24));
        scroll.addView(content);

        LinearLayout head = Ui.row(this);
        Button back = Ui.button(this, "Back", false);
        back.setOnClickListener(v -> finish());
        head.addView(back, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, Ui.dp(this, 40)));
        Ui.gap(this, head, 10);
        TextView label = Ui.text(this, "VIDEO", 11, Ui.color(this, R.color.text_secondary), true);
        head.addView(label, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1));
        content.addView(head);

        title = Ui.text(this, "Loading...", 24, Ui.color(this, R.color.text_primary), true);
        title.setPadding(0, Ui.dp(this, 12), 0, Ui.dp(this, 4));
        content.addView(title);
        meta = Ui.text(this, "", 13, Ui.color(this, R.color.text_secondary), false);
        content.addView(meta);

        progressRow = new LinearLayout(this);
        progressRow.setOrientation(LinearLayout.VERTICAL);
        progressRow.setPadding(0, Ui.dp(this, 10), 0, Ui.dp(this, 4));
        content.addView(progressRow);

        error = Ui.text(this, "", 13, Ui.color(this, R.color.status_bad), false);
        error.setVisibility(View.GONE);
        content.addView(error);

        clipsBox = new LinearLayout(this);
        clipsBox.setOrientation(LinearLayout.VERTICAL);
        clipsBox.setPadding(0, Ui.dp(this, 10), 0, 0);
        content.addView(clipsBox);
        return scroll;
    }

    private void load() {
        io.execute(() -> {
            try {
                JSONObject job = Api.getJson(base + "/api/jobs/" + jobId);
                ui.post(() -> show(job));
            } catch (Exception e) {
                ui.post(() -> {
                    if (title.getText().toString().equals("Loading...")) {
                        title.setText("Video nahi mili");
                        meta.setText(e.getMessage() == null ? "" : e.getMessage());
                    }
                });
            }
        });
    }

    private void show(JSONObject job) {
        title.setText(job.optString("title", "Video"));
        String status = job.optString("status", "");
        String stage = job.optString("stage", "");
        int pct = (int) Math.round(job.optDouble("progress", 0) * 100);
        meta.setText((status.equals("done") ? "Ready" : (stage.isEmpty() ? status : stage)) + " · " + pct + "%");

        progressRow.removeAllViews();
        if (!status.equals("done") && !status.equals("error")) {
            android.widget.ProgressBar bar = new android.widget.ProgressBar(this, null,
                    android.R.attr.progressBarStyleHorizontal);
            bar.setMax(100);
            bar.setProgress(pct);
            progressRow.addView(bar, new LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, Ui.dp(this, 8)));
        }

        String problem = job.isNull("error") ? "" : job.optString("error", "");
        if ("null".equals(problem)) problem = "";
        error.setVisibility(problem.isEmpty() ? View.GONE : View.VISIBLE);
        error.setText(problem);

        clipsBox.removeAllViews();
        JSONArray clips = job.optJSONArray("clips");
        if (clips == null || clips.length() == 0) {
            clipsBox.addView(Ui.text(this, status.equals("done")
                            ? "Is video se koi clip nahi bani." : "Clips ban rahi hain...",
                    14, Ui.color(this, R.color.text_secondary), false));
            return;
        }
        for (int i = 0; i < clips.length(); i++) {
            JSONObject clip = clips.optJSONObject(i);
            if (clip != null) clipsBox.addView(clipCard(clip));
        }
    }

    private View clipCard(JSONObject clip) {
        LinearLayout card = Ui.card(this);
        String name = clip.optString("title", "");
        if (name.isEmpty()) name = clip.optString("hook", "Clip");
        card.addView(Ui.text(this, name, 17, Ui.color(this, R.color.text_primary), true));

        int start = (int) Math.round(clip.optDouble("start", 0));
        int end = (int) Math.round(clip.optDouble("end", 0));
        String state = clip.optString("status", "");
        String line = start + "s – " + end + "s · " + state;
        card.addView(Ui.text(this, line, 12,
                Ui.color(this, state.equals("error") ? R.color.status_bad : R.color.text_secondary), false));

        String problem = clip.isNull("error") ? "" : clip.optString("error", "");
        if ("null".equals(problem)) problem = "";
        if (!problem.isEmpty()) {
            TextView p = Ui.text(this, problem, 12, Ui.color(this, R.color.status_bad), false);
            p.setPadding(0, Ui.dp(this, 6), 0, 0);
            card.addView(p);
        }

        String file = clip.optString("file", "");
        if (!file.isEmpty()) {
            LinearLayout actions = Ui.row(this);
            Button play = Ui.button(this, "Play", true);
            play.setOnClickListener(v -> open(base + "/media/" + jobId + "/" + file));
            actions.addView(play, new LinearLayout.LayoutParams(0, Ui.dp(this, 44), 1));
            Ui.gap(this, actions, 8);
            Button save = Ui.button(this, "Save / download", false);
            save.setOnClickListener(v -> open(base + "/media/" + jobId + "/" + file));
            actions.addView(save, new LinearLayout.LayoutParams(0, Ui.dp(this, 44), 1));
            LinearLayout.LayoutParams ap = new LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
            ap.topMargin = Ui.dp(this, 10);
            card.addView(actions, ap);
        }
        return card;
    }

    private void open(String url) {
        try {
            startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url)));
        } catch (Exception ignored) {
            // no player installed: the browser still opens from the full editor
        }
    }
}
