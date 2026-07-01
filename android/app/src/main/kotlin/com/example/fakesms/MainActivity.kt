package com.example.fakesms

import android.app.role.RoleManager
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "fakesms.channel"
    private val PICK_CONTACT_REQUEST_CODE = 1001
    private val REQUEST_DEFAULT_SMS_APP_CODE = 1002
    
    private var pendingResult: MethodChannel.Result? = null
    private var defaultSmsPendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "insertSMS" -> {
                    val name = call.argument<String>("name") ?: ""
                    val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    val sentTime = call.argument<Long>("sentTime") ?: System.currentTimeMillis()
                    val receivedTime = call.argument<Long>("receivedTime") ?: System.currentTimeMillis()
                    val folder = call.argument<String>("folder") ?: "Inbox"

                    try {
                        val uriString = when (folder.lowercase()) {
                            "inbox" -> "content://sms/inbox"
                            "outbox" -> "content://sms/outbox"
                            "sent" -> "content://sms/sent"
                            "draft" -> "content://sms/draft"
                            "failed" -> "content://sms/failed"
                            "queued" -> "content://sms/queued"
                            else -> "content://sms/inbox"
                        }

                        val finalAddress = if (phoneNumber.isNotBlank()) phoneNumber else name

                        val values = ContentValues().apply {
                            put("address", finalAddress)
                            put("body", message)
                            put("date", receivedTime)
                            put("date_sent", sentTime)
                            put("read", 1) // Mark as read
                        }

                        val insertedUri = contentResolver.insert(Uri.parse(uriString), values)
                        
                        if (insertedUri != null) {
                            result.success("Inserted at $insertedUri")
                        } else {
                            result.error("INSERT_FAILED", "Could not insert SMS. Ensure default SMS app or permissions.", null)
                        }
                    } catch (e: Exception) {
                        result.error("INSERT_ERROR", e.message, null)
                    }
                }
                "pickContact" -> {
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI)
                    startActivityForResult(intent, PICK_CONTACT_REQUEST_CODE)
                }
                "requestDefaultSms" -> {
                    // Check if already default
                    val defaultSmsPackage = Telephony.Sms.getDefaultSmsPackage(context)
                    if (defaultSmsPackage == packageName) {
                        result.success(true)
                        return@setMethodCallHandler
                    }

                    defaultSmsPendingResult = result
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(RoleManager::class.java)
                        if (roleManager?.isRoleAvailable(RoleManager.ROLE_SMS) == true) {
                            val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_SMS)
                            startActivityForResult(intent, REQUEST_DEFAULT_SMS_APP_CODE)
                        } else {
                            defaultSmsPendingResult?.error("ROLE_UNAVAILABLE", "SMS role not available", null)
                            defaultSmsPendingResult = null
                        }
                    } else {
                        val intent = Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT)
                        intent.putExtra(Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, packageName)
                        startActivityForResult(intent, REQUEST_DEFAULT_SMS_APP_CODE)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == PICK_CONTACT_REQUEST_CODE) {
            if (resultCode == RESULT_OK && data != null) {
                val contactUri: Uri? = data.data
                val projection: Array<String> = arrayOf(
                    ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                    ContactsContract.CommonDataKinds.Phone.NUMBER
                )
                
                if (contactUri != null) {
                    val cursor = contentResolver.query(contactUri, projection, null, null, null)
                    if (cursor != null && cursor.moveToFirst()) {
                        val nameIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                        val numberIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
                        val name = cursor.getString(nameIndex)
                        val number = cursor.getString(numberIndex)
                        cursor.close()
                        
                        val resultMap = mapOf("name" to name, "phoneNumber" to number)
                        pendingResult?.success(resultMap)
                        pendingResult = null
                        return
                    }
                }
            }
            pendingResult?.error("PICK_ERROR", "Failed to pick contact or cancelled", null)
            pendingResult = null
        } else if (requestCode == REQUEST_DEFAULT_SMS_APP_CODE) {
            val defaultSmsPackage = Telephony.Sms.getDefaultSmsPackage(context)
            if (defaultSmsPackage == packageName) {
                defaultSmsPendingResult?.success(true)
            } else {
                defaultSmsPendingResult?.success(false)
            }
            defaultSmsPendingResult = null
        } else {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }
}
