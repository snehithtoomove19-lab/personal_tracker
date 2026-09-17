package com.example.personal_tracker

import android.Manifest
import android.content.pm.PackageManager
import android.database.Cursor
import android.provider.Telephony
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {
	private var permissionResult: MethodChannel.Result? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"hasPermission" -> result.success(hasSmsPermission())
					"requestPermission" -> requestSmsPermission(result)
					"readMessages" -> {
						if (!hasSmsPermission()) {
							result.error(
								"SMS_PERMISSION_REQUIRED",
								"SMS permission is required to read messages.",
								null,
							)
						} else {
							result.success(readMessages())
						}
					}
					else -> result.notImplemented()
				}
			}
	}

	private fun hasSmsPermission(): Boolean = ContextCompat.checkSelfPermission(
		this,
		Manifest.permission.READ_SMS,
	) == PackageManager.PERMISSION_GRANTED

	private fun requestSmsPermission(result: MethodChannel.Result) {
		if (hasSmsPermission()) {
			result.success(true)
			return
		}
		permissionResult = result
		ActivityCompat.requestPermissions(
			this,
			arrayOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS),
			SMS_PERMISSION_REQUEST,
		)
	}

	override fun onRequestPermissionsResult(
		requestCode: Int,
		permissions: Array<out String>,
		grantResults: IntArray,
	) {
		super.onRequestPermissionsResult(requestCode, permissions, grantResults)
		if (requestCode != SMS_PERMISSION_REQUEST) return
		val granted = grantResults.isNotEmpty() &&
			grantResults.all { it == PackageManager.PERMISSION_GRANTED }
		permissionResult?.success(granted)
		permissionResult = null
	}

	private fun readMessages(): List<Map<String, Any>> {
		val messages = linkedMapOf<String, Map<String, Any>>()
		val pending = getSharedPreferences(SmsReceiver.PREFS, MODE_PRIVATE)
			.getString(SmsReceiver.PENDING_KEY, "[]") ?: "[]"
		val pendingArray = JSONArray(pending)
		for (index in 0 until pendingArray.length()) {
			val item = pendingArray.getJSONObject(index)
			val id = item.optString("id")
			messages[id] = mapOf(
				"id" to id,
				"address" to item.optString("address"),
				"body" to item.optString("body"),
				"date" to item.optLong("date"),
			)
		}

		val projection = arrayOf(
			Telephony.Sms._ID,
			Telephony.Sms.ADDRESS,
			Telephony.Sms.BODY,
			Telephony.Sms.DATE,
		)
		val cursor: Cursor? = contentResolver.query(
			Telephony.Sms.Inbox.CONTENT_URI,
			projection,
			null,
			null,
			"${Telephony.Sms.DATE} DESC",
		)
		cursor?.use {
			val idIndex = it.getColumnIndex(Telephony.Sms._ID)
			val addressIndex = it.getColumnIndex(Telephony.Sms.ADDRESS)
			val bodyIndex = it.getColumnIndex(Telephony.Sms.BODY)
			val dateIndex = it.getColumnIndex(Telephony.Sms.DATE)
			while (it.moveToNext()) {
				val id = it.getString(idIndex)
				messages[id] = mapOf(
					"id" to id,
					"address" to it.getString(addressIndex).orEmpty(),
					"body" to it.getString(bodyIndex).orEmpty(),
					"date" to it.getLong(dateIndex),
				)
			}
		}
		return messages.values.toList()
	}

	companion object {
		private const val CHANNEL = "personal_tracker/sms"
		private const val SMS_PERMISSION_REQUEST = 4101
	}
}
