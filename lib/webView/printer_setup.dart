import 'dart:io';
import 'dart:async';
import 'package:ygo_order/media.dart';
import 'package:zefyrka/zefyrka.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class PrinterSetup extends StatefulWidget {
  const PrinterSetup({super.key});

  @override
  State<PrinterSetup> createState() => _PrinterSetupState();
}

class _PrinterSetupState extends State<PrinterSetup> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _noOfCopiesController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final BlueThermalPrinter bluetooth =
      BlueThermalPrinter.instance; // Bluetooth printer instance

  final ZefyrController _zefyrController = ZefyrController();
  final FocusNode _focusNode = FocusNode();

  String?
      _selectedPrinterType; // To select the printer type (WiFi, Bluetooth, etc.)
  PaperSize _selectedPaperSize = PaperSize.mm58; // Default printer size
  bool _isLoading = false; // Track loading state
  DateTime? lastPressed;

  // Method to check Bluetooth permission
  Future<bool> _checkUsbPermission() async {
    PermissionStatus status;

    // For Android 10 and above, we check for storage permission
    if (await Permission.storage.isGranted) {
      return true;
    } else {
      status = await Permission.storage.request();

      // Handle status result and check if granted
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        // Open app settings to grant permissions
        Fluttertoast.showToast(
            msg:
                'USB permission is permanently denied. Please enable it from settings.');
        await openAppSettings();
        return false;
      } else {
        Fluttertoast.showToast(msg: 'USB permission not granted');
        return false;
      }
    }
  }

  Future<bool> _checkBluetoothPermission() async {
    // For Android 12+ only request Bluetooth permissions without location
    if (Platform.isAndroid && (await _getAndroidSdkInt()) >= 31) {
      PermissionStatus connectStatus = await Permission.bluetoothConnect.status;
      PermissionStatus scanStatus = await Permission.bluetoothScan.status;
      PermissionStatus advertiseStatus =
          await Permission.bluetoothAdvertise.status;

      if (connectStatus.isGranted &&
          scanStatus.isGranted &&
          advertiseStatus.isGranted) {
        return true;
      } else {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
          Permission.bluetoothAdvertise,
        ].request();

        if (statuses[Permission.bluetoothConnect]?.isGranted == true &&
            statuses[Permission.bluetoothScan]?.isGranted == true &&
            statuses[Permission.bluetoothAdvertise]?.isGranted == true) {
          return true;
        } else {
          Fluttertoast.showToast(msg: 'Bluetooth permissions not granted.');
          return false;
        }
      }
    } else {
      // On Android versions below 12, request only BluetoothConnect, as Scan may trigger location
      PermissionStatus connectStatus = await Permission.bluetoothConnect.status;

      if (connectStatus.isGranted) {
        return true;
      } else {
        PermissionStatus connectRequestStatus =
            await Permission.bluetoothConnect.request();

        if (connectRequestStatus.isGranted) {
          return true;
        } else {
          Fluttertoast.showToast(msg: 'Bluetooth permission not granted.');
          return false;
        }
      }
    }
  }

// Helper function to get Android SDK version
  Future<int> _getAndroidSdkInt() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }

  @override
  void initState() {
    super.initState();
    _loadPrinterSettings();
  }

  Future<void> _loadPrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _ipController.text = prefs.getString('printer_ip') ?? '';
    _noOfCopiesController.text = prefs.getString('copies') ?? '1';
    _selectedPrinterType = prefs.getString('printer_type') ?? 'WiFi';

    // Retrieve and set paper size
    String? savedPaperSize = prefs.getString('paper_size');
    if (savedPaperSize == '58mm') {
      _selectedPaperSize = PaperSize.mm58;
    } else {
      _selectedPaperSize = PaperSize.mm80; // Default to 80mm
    }

    await Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _printImage();
      });
    });

    setState(() {});
  }

  Future<void> _savePrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (_ipController.text.isEmpty &&
        (_selectedPrinterType == 'WiFi' ||
            _selectedPrinterType == 'Ethernet')) {
      Fluttertoast.showToast(msg: "Kindly input your printer IP address");
      return;
    }

    if (_selectedPrinterType == null) {
      Fluttertoast.showToast(
          msg: "Kindly select your printing type to proceed");
      return;
    }

    if (_noOfCopiesController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Kindly input amount of copies to print");
      return;
    }

    await prefs.setString('printer_ip', _ipController.text);
    await prefs.setString('copies', _noOfCopiesController.text);
    await prefs.setString('printer_type', _selectedPrinterType ?? 'WiFi');

    // Save the selected paper size as a string
    if (_selectedPaperSize == PaperSize.mm58) {
      await prefs.setString('paper_size', '58mm');
    } else if (_selectedPaperSize == PaperSize.mm80) {
      await prefs.setString('paper_size', '80mm');
    }

    Fluttertoast.showToast(msg: "Settings saved successfully!");
    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

// Modal dialog to configure printer settings
  void _showPrinterSettingsModal(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: const Color(0xff0a0203),
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(alignment: Alignment.topRight, children: [
                Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 60,
                    ),
                    const Text(
                      'Printer Settings',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFFFFF)),
                    ),
                    const SizedBox(
                      height: 60,
                    ),
                    DropdownButton<String>(
                      underline: Transform.translate(
                          offset: const Offset(0, 11),
                          child: const Divider(
                            color: Color(0xffFFFFFF),
                          )),
                      isExpanded: true,
                      value: _selectedPrinterType,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500),
                      dropdownColor: Colors.black,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.white),
                      items: const [
                        DropdownMenuItem(
                            value: 'WiFi',
                            child: Text('WiFi',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500))),
                        DropdownMenuItem(
                            value: 'Ethernet',
                            child: Text('Ethernet',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500))),
                        DropdownMenuItem(
                            value: 'Bluetooth',
                            child: Text('Bluetooth',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500))),
                        DropdownMenuItem(
                            value: 'USB',
                            child: Text('USB',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500))),
                      ],
                      onChanged: (String? newValue) {
                        setModalState(() {
                          _selectedPrinterType = newValue;
                        });
                      },
                      hint: const Text(
                        'Select Printer Type',
                        style: TextStyle(color: Color(0xFFFFFFFF)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // IP address for WiFi/Ethernet printers
                    if (_selectedPrinterType == 'WiFi' ||
                        _selectedPrinterType == 'Ethernet')
                      TextField(
                        controller: _ipController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Printer IP Address',
                          labelStyle: TextStyle(color: Color(0xFFFFFFFF)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.white, width: 1),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    if (_selectedPrinterType == 'WiFi' ||
                        _selectedPrinterType == 'Ethernet')
                      const SizedBox(height: 20),
                    DropdownButton<PaperSize>(
                      underline: Transform.translate(
                          offset: const Offset(0, 11),
                          child: const Divider(
                            color: Color(0xffFFFFFF),
                          )),
                      isExpanded: true,
                      value: _selectedPaperSize,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500),
                      dropdownColor: Colors.black,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.white),
                      items: const [
                        DropdownMenuItem(
                            value: PaperSize.mm58,
                            child: Text('58mm',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500))),
                        DropdownMenuItem(
                            value: PaperSize.mm80,
                            child: Text('80mm',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500))),
                      ],
                      onChanged: (PaperSize? newSize) {
                        setModalState(() {
                          _selectedPaperSize = newSize!;
                        });
                      },
                      hint: const Text(
                        'Select Paper Size',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: _noOfCopiesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Amount of Copies',
                        labelStyle: TextStyle(color: Color(0xFFFFFFFF)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 1),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 40),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            padding: MaterialStateProperty.all<EdgeInsets>(
                                const EdgeInsets.symmetric(vertical: 16.0)),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                const Color(0xFFab7421)),
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                          onPressed: () {
                            _savePrinterSettings();
                          },
                          child: const Text('Save Printer Settings'),
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    IconButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            const Color(0xFFFFFFFF)),
                        foregroundColor: MaterialStateProperty.all<Color>(
                            const Color(0xff0a0203)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 23,
                        color: Color(0xff0a0203),
                      ),
                    )
                  ],
                )
              ]),
            );
          },
        );
      },
    );
  }

  // Method to print via selected printer type
  Future<void> _printImage() async {
    final int noOfCopies = int.tryParse(_noOfCopiesController.text) ?? 1;
    _textController.text = getFormattedText();

    // Check if the text is empty after formatting
    if (_textController.text.isEmpty || _textController.text.length < 2) {
      Fluttertoast.showToast(msg: 'Kindly input your order to print!');
      return;
    }

    // Check if the number of copies is valid
    if (noOfCopies <= 0) {
      Fluttertoast.showToast(msg: 'Please enter a valid number of copies.');
      return;
    }

    // Check if the printer type requires IP and it's provided
    if (_selectedPrinterType == 'WiFi' || _selectedPrinterType == 'Ethernet') {
      if (_ipController.text.isEmpty) {
        Fluttertoast.showToast(msg: 'Please enter the printer IP address.');
        _showPrinterSettingsModal(context);
        return;
      }
    }

    setState(() {
      _isLoading = true; // Start loading
    });

    final profile = await CapabilityProfile.load();

    try {
      if (_selectedPrinterType == 'WiFi' || _selectedPrinterType == 'Ethernet') {
        Fluttertoast.showToast(msg: 'Network printing in progress...');
        // Network printer setup
        final printer = NetworkPrinter(_selectedPaperSize, profile);
        final connect = await printer.connect(_ipController.text, port: 9100);

        if (connect == PosPrintResult.success) {
          _sendPrintData(printer, noOfCopies);
        } else {
          Fluttertoast.showToast(msg: 'Failed to connect to the printer.');
        }
      } else if (_selectedPrinterType == 'Bluetooth') {
        // Bluetooth printer setup
        await _bluetoothPrintViaBluetooth(noOfCopies);
      } else if (_selectedPrinterType == 'USB') {
        // USB printer setup
        await _usbPrint(noOfCopies);
      } else {
        Fluttertoast.showToast(msg: 'Invalid printer type selected.');
      }
    } catch (e) {
      String errorMessage = _getStructuredErrorMessage(e);
      Fluttertoast.showToast(msg: 'Printing failed: $errorMessage');
    } finally {
      setState(() {
        _isLoading = false; // End loading
      });
    }
  }

  void _sendPrintData(NetworkPrinter printer, int noOfCopies) async {
    try {
      for (int i = 0; i < noOfCopies; i++) {
        await Future.delayed(const Duration(seconds: 2), () {
          if (_textController.text.isNotEmpty) {
            // Print text if available
            printer.text(
              _textController.text,
              styles: const PosStyles(
                align: PosAlign.left, // Adjust alignment as needed
                height: PosTextSize.size2,
                width: PosTextSize.size2,
              ),
              linesAfter: 1,
            );
          }
          printer.cut();
        });
      }

      Fluttertoast.showToast(msg: 'Printed $noOfCopies copies successfully.');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error while printing: $e');
    } finally {
      // Ensure the printer is disconnected
      printer.disconnect();
    }
  }

  Future<void> _bluetoothPrintViaBluetooth(int noOfCopies) async {
    bool hasBluetoothPermission = await _checkBluetoothPermission();

    if (!hasBluetoothPermission) {
      Fluttertoast.showToast(msg: 'Bluetooth permission not granted.');
      return; // Exit the function if permission is not granted
    }

    if (_textController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Kindly input your order to print!');
      return;
    }

    try {
      // Check if Bluetooth is connected
      bool? isConnected = await bluetooth.isConnected;

      // Proceed if connected
      if (isConnected == true) {
        setState(() {
          _isLoading = true; // Start loading
        });

        for (int i = 0; i < noOfCopies; i++) {
          await Future.delayed(const Duration(seconds: 2), () {
            if (_textController.text.isNotEmpty) {
              // Print text if available
              bluetooth.printCustom(_textController.text, 1, 1);
            }
            bluetooth.paperCut();
          });
        }

        Fluttertoast.showToast(msg: 'Bluetooth Print successful: $noOfCopies copies.');
      } else {
        Fluttertoast.showToast(msg: 'Failed to connect via Bluetooth.');
      }
    }  on PlatformException catch (e) {
        if (e.code == 'bluetooth_unavailable') {
          // Handle the error when Bluetooth is unavailable
          Fluttertoast.showToast(
              msg: 'Bluetooth is not available on this device.');
        } else {
          Fluttertoast.showToast(msg: 'Bluetooth error: ${e.message}');
        }
      } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() {
        _isLoading = false; // End loading
      });
    }
  }

  Future<void> _usbPrint(int noOfCopies) async {
    bool hasUsbPermission = await _checkUsbPermission();

    if (!hasUsbPermission) {
      Fluttertoast.showToast(msg: 'USB permission not granted.');
      return; // Exit if permission is not granted
    }

    if (_textController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Kindly input your order to print!');
      return;
    }

    try {
      const platform = MethodChannel('com.application.ygo_order/usb_print');

      // Check if a USB printer is connected
      final bool isUsbConnected = await platform.invokeMethod('isUsbConnected');

      if (!isUsbConnected) {
        Fluttertoast.showToast(msg: 'No USB printer connected.');
        return;
      }

      // Send print data to the USB printer (example: text)
      for (int i = 0; i < noOfCopies; i++) {
        await Future.delayed(const Duration(seconds: 2), () async {
          if (_textController.text.isNotEmpty) {
            await platform.invokeMethod('printText', {"text": _textController.text});
          }
        });
      }

      Fluttertoast.showToast(msg: 'USB Print successful: $noOfCopies copies.');
    } catch (e) {
      String errorMessage = _getStructuredErrorMessage(e);
      Fluttertoast.showToast(msg: 'USB printing failed: $errorMessage');
    } finally {
      setState(() {
        _isLoading = false; // End loading
      });
    }
  }

// Helper function to structure error messages
  String _getStructuredErrorMessage(dynamic error) {
    if (error is PlatformException) {
      return 'Error code: ${error.code}, message: ${error.message}';
    } else {
      return 'Unexpected error occurred.';
    }
  }

  String getFormattedText() {
    final doc = _zefyrController.document;
    final buffer = StringBuffer();

    for (var node in doc.root.children) {
      if (node is LineNode) {
        // Handle alignment defaults
        String alignment = 'left';

        // Check for custom styles, like heading or alignment
        if (node.style.contains(NotusAttribute.alignment)) {
          var alignmentAttr = node.style.get(NotusAttribute.alignment);
          if (alignmentAttr == NotusAttribute.alignment.center) {
            alignment = 'center';
          } else if (alignmentAttr == NotusAttribute.alignment.end) {
            alignment = 'right';
          }
        }

        // Add spacing for alignment
        if (alignment == 'center') {
          buffer.write('          '); // Add spaces for center alignment
        } else if (alignment == 'right') {
          buffer.write(
              '                    '); // Add more spaces for right alignment
        }

        // Get the text content
        String text = node.toPlainText().trim();
        buffer.write(text);
        buffer.write('\n'); // Add newline after each line
      } else if (node is BlockNode) {
        // Handle blocks (e.g., lists, quotes, etc.)
        for (var child in node.children) {
          if (child is LineNode) {
            buffer.write('- ${child.toPlainText().trim()}\n');
          }
        }
      }
    }
    if (kDebugMode) {
      print('buffer.toString(): ${buffer.toString()}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          final currentTime = DateTime.now();
          final backButtonHasBeenPressedTwice = lastPressed != null &&
              currentTime.difference(lastPressed!) < const Duration(seconds: 2);

          if (backButtonHasBeenPressedTwice) {
            SystemNavigator.pop();
            return true;
          } else {
            lastPressed = currentTime;
            Fluttertoast.showToast(
              msg: "Tap again to exit",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );

            return false;
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xff0a0203),
          appBar: AppBar(
            backgroundColor: const Color(0xff0a0203),
            surfaceTintColor: Colors.blue,
            leading: null,
            title: Transform.translate(
                offset: const Offset(0, 0),
                child: const Text(
                  'Order Slip Printer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFFFFF),
                  ),
                )),
            actions: [
              IconButton(
                onPressed: () => _showPrinterSettingsModal(context),
                icon: const Icon(
                  Icons.settings_outlined,
                  size: 28,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(
                width: 10,
              )
            ],
          ),
          body: SizedBox(
            height: height,
            width: width,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Container(
                          //   padding: const EdgeInsets.only(top: 30),
                          //   child: const Text(
                          //     '',
                          //     // 'Enter order to print',
                          //     style: TextStyle(
                          //       fontSize: 16,
                          //       fontWeight: FontWeight.w500,
                          //       color: Color(0xFFFFFFFF),
                          //     ),
                          //   ),
                          // ),

                          // Original toolbar with added alignment buttons
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // Custom alignment buttons row
                                Container(
                                  color: const Color(0xff0a0203),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.format_align_left,
                                            color: Colors.white),
                                        onPressed: () =>
                                            _handleAlignment('left'),
                                        tooltip: 'Align Left',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.format_align_center,
                                            color: Colors.white),
                                        onPressed: () =>
                                            _handleAlignment('center'),
                                        tooltip: 'Align Center',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.format_align_right,
                                            color: Colors.white),
                                        onPressed: () =>
                                            _handleAlignment('right'),
                                        tooltip: 'Align Right',
                                      ),
                                    ],
                                  ),
                                ),

                                Theme(
                                  data: Theme.of(context).copyWith(
                                    textTheme:
                                        Theme.of(context).textTheme.copyWith(
                                              bodyText2: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                  ),
                                  child: ZefyrToolbar.basic(
                                      controller: _zefyrController),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  textSelectionTheme:
                                      const TextSelectionThemeData(
                                    cursorColor: Colors
                                        .white, // Set cursor color to white
                                  ),
                                ),
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 8, 8, 8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                        0xff0a0203), // Same background color as TextField
                                    border: Border.all(
                                        color: const Color(
                                            0xffd3d3d3)), // Enabled border color
                                    borderRadius: BorderRadius.circular(0),
                                  ),
                                  child: DefaultTextStyle(
                                    style: const TextStyle(
                                      color: Colors.white,
                                      height:
                                          1.1, // Set a smaller value to reduce space between lines
                                      fontSize: 12,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minHeight: 120, // Minimum height
                                        // maxHeight:
                                        //     200, // Limit expansion; editor scrolls after this height
                                      ),
                                      child: ZefyrEditor(
                                        controller: _zefyrController,
                                        focusNode: _focusNode,
                                        scrollable: true,
                                        padding: EdgeInsets
                                            .zero, // Use zero padding here, already applied on the container
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all<EdgeInsets>(
                                    const EdgeInsets.symmetric(vertical: 16.0)),
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        const Color(0xFFab7421)),
                                foregroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.white),
                                shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                              ),
                              onPressed: _printImage,
                              child: _isLoading
                                  ? Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 0, vertical: 0),
                                      width: 17,
                                      height: 17,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Color(0xFFEEEEEE)),
                                      ),
                                    )
                                  : const Text('PRINT SLIP'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  void _handleAlignment(String alignment) {
    final selection = _zefyrController.selection;
    if (selection != null) {
      // Try using block attribute
      if (alignment == 'left') {
        _zefyrController.formatSelection(NotusAttribute.alignment.justify);
      } else if (alignment == 'center') {
        _zefyrController.formatSelection(NotusAttribute.alignment.center);
      } else {
        _zefyrController.formatSelection(NotusAttribute.alignment.end);
      }
    }
  }
}
