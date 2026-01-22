import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:production/l10n/app_localizations.dart';

class ServerAddress extends StatefulWidget {
  const ServerAddress({super.key});

  @override
  ServerAddressState createState() => ServerAddressState();
}

class ServerAddressState extends State<ServerAddress> {
  final addressController = TextEditingController();
  final portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  void loadUserInfo() async {
    String apiAddress = '';
    String address1 = '', address2 = '';
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiAddress = prefs.getString('address') ?? '';
      if (apiAddress.contains('://')){
        address1 = apiAddress.substring(0, apiAddress.indexOf('://') + 3);
        address2 = apiAddress.substring(apiAddress.indexOf('://') + 3);
      }
      addressController.text = address1 + address2.split(':')[0];
      portController.text = address2.split(':').length > 1 ? address2.split(':')[1] : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.serverSettingTitle),
        actions: [
          IconButton(
            onPressed: () {
              addressController.text = 'http://192.168.23.246';
              portController.text = '88';
            },
            icon: const Icon(Icons.terminal)
          ),
          IconButton(
            onPressed: () {
              addressController.text = 'http://prodapp.tythac.com.vn';
              portController.text = '80';
            },
            icon: const Icon(Icons.refresh)
          ),
          /*IconButton(
            icon: const Icon(Icons.qr_code, size: 32),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))
                    ),
                    contentPadding: const EdgeInsets.all(16.0),
                    scrollable: true,
                    content: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.width * 0.6,
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: QrImageView(
                            padding: EdgeInsets.zero,
                            data: addressController.text + (portController.text != '' ? ':${portController.text}' : ''),
                            version: QrVersions.auto,
                            //size: 100.0,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(addressController.text + (portController.text != '' ? ':${portController.text}' : '')),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.expand, size: 28),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    contentPadding: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))
                    ),
                    scrollable: true,
                    content: Center(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.width * 0.9,
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: QRView(
                          key: qrKey,
                          onQRViewCreated: (QRViewController controller) {
                            setState(() {
                              qrController = controller;
                            });
                            controller.scannedDataStream.listen((scanData) {
                              Navigator.of(context).pop();
                              setState(() {
                                addressController.text = scanData.code!.split(':')[0];
                                portController.text = scanData.code!.split(':').length > 1 ? scanData.code!.split(':')[1] : '';
                              });
                            });
                          },
                          overlay: QrScannerOverlayShape(
                            borderColor: Colors.red,
                            borderRadius: 8,
                            borderLength: 30,
                            borderWidth: 8,
                            cutOutSize: MediaQuery.of(context).size.width * 0.7
                          ),
                          onPermissionSet: (QRViewController ctrl, bool p) {
                            if (!p) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('no Permission')),
                              );
                            }
                          }
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          )*/
        ],
      ),
      backgroundColor: Colors.grey[300],
      body: Column(
        children: [
          ListTile(
            title: TextField(
              controller: addressController,
              decoration: InputDecoration(
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                hintText: AppLocalizations.of(context)!.serverSettingAddress,
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  height: 1.4
                )
              )
            )
          ),
          ListTile(
            title: TextField(
              controller: portController,
              decoration: InputDecoration(
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                hintText: AppLocalizations.of(context)!.serverSettingPort,
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  height: 1.4
                )
              )
            )
          ),
          const Expanded(child: SizedBox()),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton(
              onPressed: () async {
                final userInfo = await SharedPreferences.getInstance();
                userInfo.setString('address', addressController.text + (portController.text != '' ? ':${portController.text}' : ''));
                if (!mounted) return;
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4))
                ),
                side: const BorderSide(color: Colors.grey)
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(AppLocalizations.of(context)!.serverSettingSave, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, height: 1.4)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}