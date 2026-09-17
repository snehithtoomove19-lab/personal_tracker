package com.example.personal_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.telephony.SmsMessage
import org.json.JSONArray
import org.json.JSONObject

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != "android.provider.Telephony.SMS_RECEIVED") return

        val bundle: Bundle = intent.extras ?: return
        val rawPdus = bundle.get("pdus") as? Array<*> ?: return
        val format = bundle.getString("format")
        val pending = JSONArray(
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(PENDING_KEY, "[]") ?: "[]"
        )

        rawPdus.mapNotNull { pdu ->
            if (format == null) {
                SmsMessage.createFromPdu(pdu as ByteArray)
            } else {
                SmsMessage.createFromPdu(pdu as ByteArray, format)
            }
        }.forEach { sms ->
            pending.put(
                JSONObject().apply {
                    put("id", "broadcast-${sms.timestampMillis}-${sms.originatingAddress}")
                    put("address", sms.originatingAddress ?: "")
                    put("body", sms.messageBody ?: "")
                    put("date", sms.timestampMillis)
                }
            )
        }

        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(PENDING_KEY, pending.toString())
            .apply()
    }

    companion object {
        const val PREFS = "personal_tracker_sms"
        const val PENDING_KEY = "pending_sms"
    }
}
