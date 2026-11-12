package com.itsash.panchang

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONObject
import java.util.Calendar

/**
 * Home-screen widget: today's panchang. The data (next ~30 days, computed by the Dart engine) is
 * stored as one JSON string in SharedPreferences; this class only picks today's entry by local date.
 */
class PanchangWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        val views = build(context)
        for (id in appWidgetIds) manager.updateAppWidget(id, views)
    }

    companion object {
        private const val PREFS = "panchang_widget"
        private const val KEY = "data"

        private val LABELS = intArrayOf(R.id.row1_label, R.id.row2_label, R.id.row3_label, R.id.row4_label, R.id.row5_label)
        private val VALUES = intArrayOf(R.id.row1_value, R.id.row2_value, R.id.row3_value, R.id.row4_value, R.id.row5_value)

        fun save(context: Context, json: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, json).apply()
        }

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, PanchangWidget::class.java))
            if (ids.isEmpty()) return
            val views = build(context)
            for (id in ids) manager.updateAppWidget(id, views)
        }

        private fun todayKey(): String {
            val c = Calendar.getInstance()
            return "%04d-%02d-%02d".format(c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1, c.get(Calendar.DAY_OF_MONTH))
        }

        private fun build(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_panchang)
            val open = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, open)

            var place = ""
            var message = context.getString(R.string.widget_stale)
            var day: JSONObject? = null
            try {
                val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
                if (raw != null) {
                    val root = JSONObject(raw)
                    place = root.optString("place")
                    message = root.optString("msg", message)
                    day = root.optJSONObject("days")?.optJSONObject(todayKey())
                }
            } catch (_: Exception) {
                day = null
            }

            views.setTextViewText(R.id.widget_place, place)
            if (day == null) {
                views.setTextViewText(R.id.widget_date, message)
                for (i in LABELS.indices) {
                    views.setTextViewText(LABELS[i], "")
                    views.setTextViewText(VALUES[i], "")
                }
                return views
            }

            views.setTextViewText(R.id.widget_date, day.optString("t"))
            val rows = day.optJSONArray("rows")
            for (i in LABELS.indices) {
                val row = rows?.optJSONArray(i)
                views.setTextViewText(LABELS[i], row?.optString(0) ?: "")
                views.setTextViewText(VALUES[i], row?.optString(1) ?: "")
            }
            return views
        }
    }
}
