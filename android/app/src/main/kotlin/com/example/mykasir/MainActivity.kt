package com.example.mykasir

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "mykasir/bluetooth"
	private val REQUEST_CODE_BT = 1001
	private var pendingResult: MethodChannel.Result? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
				when (call.method) {
					"ensurePermissions" -> {
						// Request runtime BLUETOOTH_CONNECT / BLUETOOTH_SCAN on Android 12+
						if (hasBtPermission()) {
							result.success(true)
						} else {
							pendingResult = result
							ActivityCompat.requestPermissions(
								this,
								arrayOf(android.Manifest.permission.BLUETOOTH_CONNECT, android.Manifest.permission.BLUETOOTH_SCAN),
								REQUEST_CODE_BT
							)
						}
					}
					"getBondedDevices" -> {
						val list = getBondedDevices()
						result.success(list)
					}
					"printBytes" -> {
						val mac = call.argument<String>("mac")
						val bytes = call.argument<ByteArray>("bytes")
						if (mac == null || bytes == null) {
							result.error("ARG", "mac/bytes null", null)
							return@setMethodCallHandler
						}
						Thread {
							try {
								printBytes(mac, bytes)
								runOnUiThread { result.success(true) }
							} catch (e: Exception) {
								runOnUiThread { result.error("PRINT", e.message, null) }
							}
						}.start()
					}
						else -> result.notImplemented()
				}
			}
	}

	override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
		super.onRequestPermissionsResult(requestCode, permissions, grantResults)
		if (requestCode == REQUEST_CODE_BT) {
			val granted = grantResults.isNotEmpty() && grantResults.all { it == android.content.pm.PackageManager.PERMISSION_GRANTED }
			pendingResult?.success(granted)
			pendingResult = null
		}
	}

	private fun hasBtPermission(): Boolean {
		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
		} else {
			true
		}
	}

	@SuppressLint("MissingPermission")
	private fun getBondedDevices(): List<Map<String, String>> {
		val out = mutableListOf<Map<String, String>>()
		val manager = getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
		val adapter: BluetoothAdapter? = manager.adapter
		if (adapter == null) return out
		if (!hasBtPermission()) return out
		val bonded = adapter.bondedDevices
		for (d in bonded) {
			out.add(mapOf("name" to (d.name ?: "Perangkat"), "mac" to d.address))
		}
		return out
	}

	@SuppressLint("MissingPermission")
	private fun printBytes(mac: String, bytes: ByteArray) {
		val manager = getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
		val adapter: BluetoothAdapter = manager.adapter
		if (!hasBtPermission()) throw Exception("BLUETOOTH_CONNECT not granted")
		val device: BluetoothDevice = adapter.getRemoteDevice(mac)
		// Standard SerialPortService ID for SPP
		val uuid = java.util.UUID.fromString("00001101-0000-1000-8000-00805f9b34fb")
		val socket = device.createRfcommSocketToServiceRecord(uuid)
		adapter.cancelDiscovery()
		socket.connect()
		socket.outputStream.use { os ->
			os.write(bytes)
			os.flush()
		}
		socket.close()
	}
}
