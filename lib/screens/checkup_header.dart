import 'dart:async';

import 'package:flutter/material.dart';
import 'package:test/screens/checkup_item.dart';

class CheckupHeader extends StatefulWidget {
  static String routeName = "/checkupheader";
  @override
  _CheckupHeaderPageState createState() => _CheckupHeaderPageState();
}

class _CheckupHeaderPageState extends State<CheckupHeader> {
  TextEditingController licenseHController = TextEditingController();
  TextEditingController licenseTController = TextEditingController();
  bool enableNext = true;
  late Timer timer;

  @override
  void initState() {
    super.initState();
  }

  void alertDialog(String msg, String type) {
    Icon icon = Icon(Icons.info_outline, color: Colors.lightBlue);
    switch (type) {
      case "Success":
        icon = Icon(Icons.check_circle_outline, color: Colors.lightGreen);
        break;
      case "Error":
        icon = Icon(Icons.error_outline, color: Colors.redAccent);
        break;
      case "Warning":
        icon = Icon(Icons.warning_amber_outlined, color: Colors.orangeAccent);
        break;
      case "Infomation":
        icon = Icon(Icons.info_outline, color: Colors.lightBlue);
        break;
    }

    showDialog(
        context: context,
        builder: (BuildContext builderContext) {
          timer = Timer(Duration(seconds: 5), () {
            Navigator.of(context, rootNavigator: true).pop();
          });

          return AlertDialog(
            title: Row(children: [icon, Text(" " + type)]),
            content: Text(msg),
          );
        }).then((val) {
      if (timer.isActive) {
        timer.cancel();
      }
    });
  }

  void showErrorDialog(String error) {
    //MyWidget.showMyAlertDialog(context, "Error", error);
    alertDialog(error, 'Error');
  }

  void showSuccessDialog(String success) {
    //MyWidget.showMyAlertDialog(context, "Success", success);
    alertDialog(success, 'Success');
  }

  Future<void> checkLicense() async {
    try {
      if (licenseHController.text.toString() != "" ||
          licenseTController.text.toString() != "") {
        setState(() {
          licenseHController.text = "";
          licenseTController.text = "";
        });
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => CheckupItemPage()));
      } else {
        setState(() {
          licenseHController.text = "";
          licenseTController.text = "";
        });
        showErrorDialog('Please Enter Data!');
      }
    } catch (e) {
      print("Error occured while checkLicense");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            toolbarHeight: 50,
            leading: BackButton(color: Colors.black),
            backgroundColor: Colors.white,
            title: Text(
              'CHECK-UP',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.black, fontSize: 18),
            )),
        resizeToAvoidBottomInset: false,
        body: Container(
            child: SingleChildScrollView(
          child: Center(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: MediaQuery.of(context).size.height / 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .center, //Center Row contents horizontally,
                crossAxisAlignment:
                    CrossAxisAlignment.center, //Center Row contents vertically,
                children: <Widget>[
                  new SizedBox(
                      width: 200.0,
                      height: 100.0,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.go,
                        onFieldSubmitted: (value) {},
                        decoration: InputDecoration(
                          filled: true,
                          hintText: 'Enter License Head',
                          labelText: 'License Head',
                          border: OutlineInputBorder(),
                          isDense: true, // Added this
                          contentPadding: EdgeInsets.all(23), //
                        ),
                        controller: licenseHController,
                      )),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .center, //Center Row contents horizontally,
                crossAxisAlignment:
                    CrossAxisAlignment.center, //Center Row contents vertically,
                children: <Widget>[
                  new SizedBox(
                      width: 200.0,
                      height: 100.0,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.go,
                        onFieldSubmitted: (value) {},
                        decoration: InputDecoration(
                          filled: true,
                          hintText: 'Enter License Trailer',
                          labelText: 'License Trailer',
                          border: OutlineInputBorder(),
                          isDense: true, // Added this
                          contentPadding: EdgeInsets.all(23), //
                        ),
                        controller: licenseTController,
                      )),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .center, //Center Row contents horizontally,
                crossAxisAlignment:
                    CrossAxisAlignment.center, //Center Row contents vertically,
                children: <Widget>[
                  new RaisedButton(
                    color: enableNext == true ? Colors.green : Colors.grey,
                    child: const Text('Next',
                        style: TextStyle(
                          color: Colors.white,
                        )),
                    onPressed: enableNext
                        ? () {
                            checkLicense();
                          }
                        : null,
                  ),
                ],
              ),
            ],
          )),
        )));
  }
}