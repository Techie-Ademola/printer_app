package com.application.ygo_order

import android.content.Context
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.FileDescriptor
import java.io.FileOutputStream
import java.io.OutputStream
import android.os.ParcelFileDescriptor

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.application.ygo_order/usb_print"
    private val CLASS_PRINTER = 7  // USB Class for printers

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "isUsbConnected" -> {
                        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
                        val deviceList = usbManager.deviceList
                        val printerDevice = deviceList.values.firstOrNull { isUsbPrinter(it) }

                        if (printerDevice != null) {
                            result.success(true)  // USB printer is connected
                        } else {
                            result.success(false) // No USB printer connected
                        }
                    }
                    "printText" -> {
                        val textToPrint = call.argument<String>("text")
                        if (textToPrint != null) {
                            val isSuccess = printViaUsb(textToPrint)
                            result.success(isSuccess)
                        } else {
                            result.error("INVALID_DATA", "Text to print is missing", null)
                        }
                    }
                    "printImage" -> {
                        val imageBytes = call.argument<ByteArray>("imageBytes")
                        if (imageBytes != null) {
                            val isSuccess = printImageViaUsb(imageBytes)
                            result.success(isSuccess)
                        } else {
                            result.error("INVALID_DATA", "Image data is missing", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    // Helper function to determine if a USB device is a printer
    private fun isUsbPrinter(device: UsbDevice): Boolean {
        return device.deviceClass == CLASS_PRINTER
    }

    // Print text via USB
    private fun printViaUsb(text: String): Boolean {
        try {
            val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
            val deviceList = usbManager.deviceList
            val printerDevice = deviceList.values.firstOrNull { isUsbPrinter(it) }

            if (printerDevice != null) {
                val connection = usbManager.openDevice(printerDevice)
                connection?.apply {
                    // Convert the Int fileDescriptor to FileDescriptor using ParcelFileDescriptor
                    val parcelFileDescriptor = ParcelFileDescriptor.adoptFd(connection.fileDescriptor)
                    val fileDescriptor: FileDescriptor = parcelFileDescriptor.fileDescriptor
                    val outputStream: OutputStream = FileOutputStream(fileDescriptor)
                    outputStream.write(text.toByteArray())
                    outputStream.close()
                    connection.close()
                    return true
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }

    // Print image via USB
    private fun printImageViaUsb(imageBytes: ByteArray): Boolean {
        try {
            val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
            val deviceList = usbManager.deviceList
            val printerDevice = deviceList.values.firstOrNull { isUsbPrinter(it) }

            if (printerDevice != null) {
                val connection = usbManager.openDevice(printerDevice)
                connection?.apply {
                    // Convert the Int fileDescriptor to FileDescriptor using ParcelFileDescriptor
                    val parcelFileDescriptor = ParcelFileDescriptor.adoptFd(connection.fileDescriptor)
                    val fileDescriptor: FileDescriptor = parcelFileDescriptor.fileDescriptor
                    val outputStream: OutputStream = FileOutputStream(fileDescriptor)
                    outputStream.write(imageBytes)
                    outputStream.close()
                    connection.close()
                    return true
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }
}
