package com.clippulse.app;

import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.widget.Toast;

/** Starts the local ClipPulse engine through Termux, because Android apps cannot run Python directly. */
final class ServerStarter {
    private ServerStarter() {}

    static final String TERMUX_PACKAGE = "com.termux";
    static final String START_COMMAND =
            "cd ~/ClipPulse 2>/dev/null || cd ~/PeakCut; bash scripts/termux/start.sh";

    static boolean start(Activity activity) {
        Intent intent = new Intent("com.termux.RUN_COMMAND");
        intent.setClassName(TERMUX_PACKAGE, "com.termux.app.RunCommandService");
        intent.putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash");
        intent.putExtra("com.termux.RUN_COMMAND_ARGUMENTS", new String[]{"-lc", START_COMMAND});
        intent.putExtra("com.termux.RUN_COMMAND_WORKDIR", "/data/data/com.termux/files/home");
        intent.putExtra("com.termux.RUN_COMMAND_BACKGROUND", true);
        intent.putExtra("com.termux.RUN_COMMAND_SESSION_ACTION", "0");
        try {
            activity.startService(intent);
            return true;
        } catch (Exception e) {
            // This Termux build has no RUN_COMMAND service: copy the start command and open Termux instead.
            copyStartCommand(activity);
            openTermux(activity);
            return false;
        }
    }

    static void copyStartCommand(Activity activity) {
        ClipboardManager cm = (ClipboardManager) activity.getSystemService(Context.CLIPBOARD_SERVICE);
        if (cm != null) {
            cm.setPrimaryClip(ClipData.newPlainText("ClipPulse start command", START_COMMAND));
            Toast.makeText(activity,
                    "Start command copy ho gaya. Termux me paste karke Enter dabayein.",
                    Toast.LENGTH_LONG).show();
        }
    }

    static void openTermux(Activity activity) {
        Intent intent = activity.getPackageManager().getLaunchIntentForPackage(TERMUX_PACKAGE);
        if (intent == null) {
            Toast.makeText(activity, "Termux install nahi hai. Pehle Termux install karein.", Toast.LENGTH_LONG).show();
            return;
        }
        activity.startActivity(intent);
    }

    /** The one-time Termux setting that lets ClipPulse start the engine by itself. */
    static String setupCommand() {
        return "echo 'allow-external-apps = true' >> ~/.termux/termux.properties && termux-reload-settings";
    }
}
