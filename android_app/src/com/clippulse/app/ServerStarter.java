package com.clippulse.app;

import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.widget.Toast;

/** Starts the local ClipPulse engine through Termux, because Android apps cannot run Python directly. */
final class ServerStarter {
    private ServerStarter() {}

    static final String TERMUX_PACKAGE = "com.termux";
    private static final String RUN_COMMAND_SERVICE = "com.termux.app.RunCommandService";

    /** The engine is kept running: if it ever stops, this starts it again by itself. */
    static final String START_COMMAND =
            "cd ~/ClipPulse 2>/dev/null || cd ~/PeakCut; bash scripts/termux/keepalive.sh";

    /** Some Termux builds (the Play Store one, for example) cannot be asked to run a command by another app. */
    static boolean canCommand(Context context) {
        try {
            context.getPackageManager().getServiceInfo(
                    new ComponentName(TERMUX_PACKAGE, RUN_COMMAND_SERVICE), 0);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    static boolean installed(Context context) {
        try {
            context.getPackageManager().getPackageInfo(TERMUX_PACKAGE, 0);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    static boolean start(Activity activity) {
        if (!canCommand(activity)) {
            // This Termux cannot take a command from another app: hand the command over instead.
            copyStartCommand(activity);
            openTermux(activity);
            return false;
        }
        Intent intent = new Intent("com.termux.RUN_COMMAND");
        intent.setClassName(TERMUX_PACKAGE, RUN_COMMAND_SERVICE);
        intent.putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash");
        intent.putExtra("com.termux.RUN_COMMAND_ARGUMENTS", new String[]{"-lc", START_COMMAND});
        intent.putExtra("com.termux.RUN_COMMAND_WORKDIR", "/data/data/com.termux/files/home");
        intent.putExtra("com.termux.RUN_COMMAND_BACKGROUND", true);
        intent.putExtra("com.termux.RUN_COMMAND_SESSION_ACTION", "0");
        try {
            activity.startService(intent);
            return true;
        } catch (Exception e) {
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

    /** Why the engine lives in Termux, in plain words. */
    static String explanation(Context context) {
        String base = "ClipPulse ka engine Python aur ffmpeg par chalta hai (video katna, captions, awaaz se "
                + "transcript). Android seedha Python nahi chala sakta, isliye engine phone ke Termux ke andar "
                + "chalta hai.\n\n";
        if (!installed(context)) {
            return base + "Is phone par Termux nahi mila. Termux (F-Droid se) install karein, phir project "
                    + "folder me ek baar engine start karein.";
        }
        if (!canCommand(context)) {
            return base + "Aapka Termux build doosri app se command nahi leta (Play Store wala build aisa hi hai). "
                    + "Isliye Start engine dabane par command copy hota hai aur Termux khulta hai: ek baar paste "
                    + "karke Enter dabayein. Uske baad engine chalta rehta hai, band ho to khud start ho jata hai.";
        }
        return base + "Start engine dabane par app khud Termux me engine chala deta hai.";
    }
}
