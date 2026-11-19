package com.clippulse.app;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

/** Small helpers so the native screens are built from code, with the same colours as the web app. */
final class Ui {
    private Ui() {}

    static int dp(Context c, int n) {
        return Math.round(n * c.getResources().getDisplayMetrics().density);
    }

    static int color(Context c, int id) {
        return c.getResources().getColor(id, c.getTheme());
    }

    static TextView text(Context c, String value, int sp, int color, boolean bold) {
        TextView v = new TextView(c);
        v.setText(value);
        v.setTextSize(sp);
        v.setTextColor(color);
        if (bold) v.setTypeface(v.getTypeface(), android.graphics.Typeface.BOLD);
        v.setLineSpacing(dp(c, 2), 1f);
        return v;
    }

    static LinearLayout card(Context c) {
        LinearLayout box = new LinearLayout(c);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(c, 16), dp(c, 16), dp(c, 16), dp(c, 16));
        box.setBackgroundResource(R.drawable.card_bg);
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        p.bottomMargin = dp(c, 14);
        box.setLayoutParams(p);
        return box;
    }

    static Button button(Context c, String label, boolean primary) {
        Button b = new Button(c);
        b.setText(label);
        b.setAllCaps(false);
        b.setTextSize(14);
        b.setTextColor(primary ? Color.WHITE : color(c, R.color.brand));
        b.setBackgroundResource(primary ? R.drawable.button_bg : R.drawable.card_bg);
        b.setMinHeight(dp(c, 46));
        return b;
    }

    static View dot(Context c, int color) {
        View v = new View(c);
        GradientDrawable shape = new GradientDrawable();
        shape.setShape(GradientDrawable.OVAL);
        shape.setColor(color);
        v.setBackground(shape);
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(dp(c, 10), dp(c, 10));
        p.rightMargin = dp(c, 10);
        v.setLayoutParams(p);
        return v;
    }

    static LinearLayout row(Context c) {
        LinearLayout r = new LinearLayout(c);
        r.setOrientation(LinearLayout.HORIZONTAL);
        r.setGravity(Gravity.CENTER_VERTICAL);
        return r;
    }

    static void gap(Context c, LinearLayout box, int dp) {
        View v = new View(c);
        v.setLayoutParams(new LinearLayout.LayoutParams(dp(c, dp), 1));
        box.addView(v);
    }
}
