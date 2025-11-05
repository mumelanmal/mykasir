package com.example.mykasir

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
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

	// Persistent socket map to reuse RFCOMM connections per MAC
	private val socketMap: MutableMap<String, android.bluetooth.BluetoothSocket> = mutableMapOf()
	private val socketLock = Any()
	private val socketLastUsed: MutableMap<String, Long> = mutableMapOf()
	private val SOCKET_IDLE_TIMEOUT_MS = 5 * 60 * 1000L // 5 minutes

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
						"openConnection" -> {
							val mac = call.argument<String>("mac")
							if (mac == null) {
								result.error("ARG", "mac null", null)
								return@setMethodCallHandler
							}
							Thread {
								try {
									val manager = getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
									val adapter: BluetoothAdapter = manager.adapter
									val device: BluetoothDevice = adapter.getRemoteDevice(mac)
									openSocketForMac(device, java.util.UUID.fromString("00001101-0000-1000-8000-00805f9b34fb"))
									runOnUiThread { result.success(true) }
								} catch (e: Exception) {
									runOnUiThread { result.error("OPEN", e.message, null) }
								}
							}.start()
						}
						"closeConnection" -> {
							val mac = call.argument<String>("mac")
							if (mac == null) {
								result.error("ARG", "mac null", null)
								return@setMethodCallHandler
							}
							Thread {
								try {
									closeSocket(mac)
									runOnUiThread { result.success(true) }
								} catch (e: Exception) {
									runOnUiThread { result.error("CLOSE", e.message, null) }
								}
							}.start()
						}
						"isConnected" -> {
							val mac = call.argument<String>("mac")
							if (mac == null) {
								result.error("ARG", "mac null", null)
								return@setMethodCallHandler
							}
							val s = synchronized(socketLock) { socketMap[mac] }
							result.success(s != null && s.isConnected)
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
		val uuid = java.util.UUID.fromString("00001101-0000-1000-8000-00805f9b34fb")

		// Ensure discovery is cancelled before connect
		try {
			adapter.cancelDiscovery()
		} catch (_: Exception) {}

		val socket = openSocketForMac(device, uuid)

		// Write using the existing socket. Keep the socket open for reuse; do not close the output stream.
		try {
			android.util.Log.d("MyKasirBT", "Writing ${bytes.size} bytes to $mac")
			val os = socket.outputStream
			os.write(bytes)
			os.flush()
			socketLastUsed[mac] = System.currentTimeMillis()
			android.util.Log.d("MyKasirBT", "Write complete to $mac")
		} catch (e: Exception) {
			android.util.Log.e("MyKasirBT", "Write failed to $mac: ${e.message}", e)
			// close and remove socket to force reconnect next time
			closeSocket(mac)
			throw e
		}
	}

	@SuppressLint("MissingPermission")
	private fun openSocketForMac(device: BluetoothDevice, uuid: java.util.UUID): BluetoothSocket {
		val mac = device.address
		synchronized(socketLock) {
			// Return existing connected socket if available
			val existing = socketMap[mac]
			if (existing != null && existing.isConnected) {
				val last = socketLastUsed[mac] ?: 0L
				val idle = System.currentTimeMillis() - last
				if (idle <= SOCKET_IDLE_TIMEOUT_MS) {
					android.util.Log.d("MyKasirBT", "Reusing existing socket for $mac (idle ${idle}ms)")
					return existing
				} else {
					android.util.Log.d("MyKasirBT", "Socket idle for ${idle}ms > timeout, closing and reopening for $mac")
					try { existing.close() } catch (_: Exception) {}
					socketMap.remove(mac)
					socketLastUsed.remove(mac)
				}
			}

			val adapter = (getSystemService(BLUETOOTH_SERVICE) as BluetoothManager).adapter
			var lastException: Exception? = null
			// Try strategies in order
			try {
				android.util.Log.d("MyKasirBT", "Attempting secure socket for $mac")
				val s = device.createRfcommSocketToServiceRecord(uuid)
				s.connect()
				socketMap[mac] = s
				android.util.Log.d("MyKasirBT", "Secure socket connected for $mac")
				return s
			} catch (e: Exception) {
				lastException = e
				android.util.Log.w("MyKasirBT", "Secure socket failed for $mac: ${e.message}")
			}

			try {
				android.util.Log.d("MyKasirBT", "Attempting insecure socket for $mac")
				val s2 = device.createInsecureRfcommSocketToServiceRecord(uuid)
				s2.connect()
				socketMap[mac] = s2
				android.util.Log.d("MyKasirBT", "Insecure socket connected for $mac")
				return s2
			} catch (e: Exception) {
				lastException = e
				android.util.Log.w("MyKasirBT", "Insecure socket failed for $mac: ${e.message}")
			}

			// Reflection fallback
			try {
				android.util.Log.d("MyKasirBT", "Attempting reflection fallback for $mac")
				val m = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
				val s3 = m.invoke(device, 1) as BluetoothSocket
				s3.connect()
				socketMap[mac] = s3
				android.util.Log.d("MyKasirBT", "Reflection socket connected for $mac")
				return s3
			} catch (e: Exception) {
				lastException = e
				android.util.Log.e("MyKasirBT", "All socket strategies failed for $mac: ${e.message}", e)
				// Ensure any partially opened socket is closed
				socketMap.remove(mac)?.let {
					try { it.close() } catch (_: Exception) {}
				}
				throw lastException ?: Exception("Failed to open bluetooth socket for $mac")
			}
		}
	}

	private fun closeSocket(mac: String) {
		synchronized(socketLock) {
			socketMap.remove(mac)?.let { s ->
				try {
					android.util.Log.d("MyKasirBT", "Closing socket for $mac")
					s.close()
				} catch (e: Exception) {
					android.util.Log.w("MyKasirBT", "Error closing socket for $mac: ${e.message}")
				}
			}
		}
	}

	override fun onDestroy() {
		super.onDestroy()
		// Close all sockets
		synchronized(socketLock) {
			socketMap.keys.toList().forEach { mac ->
				try { socketMap.remove(mac)?.close() } catch (_: Exception) {}
			}
		}
	}
}
