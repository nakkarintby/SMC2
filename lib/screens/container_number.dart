import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_session/flutter_session.dart';
import 'package:http/http.dart' as http;
import 'package:multi_image_picker2/multi_image_picker2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:image/image.dart' as img;
import 'package:location/location.dart';
import 'package:test/class/containerdocument.dart';
import 'package:test/class/createimage.dart';
import 'package:test/class/getsequnce.dart';
import 'package:test/class/imagesequence.dart';
import 'package:test/class/uploadimage.dart';
import 'package:test/screens/register.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class ContainerNumber extends StatefulWidget {
  @override
  _ContainerNumberState createState() => _ContainerNumberState();
}

class _ContainerNumberState extends State<ContainerNumber> {
  TextEditingController documentController = TextEditingController();
  bool documentVisible = false;
  bool documentReadonly = false;
  Color documentColor = Color(0xFFFFFFFF);
  bool takePhotoEnabled = false;
  bool uploadEnabled = false;
  bool finishEnabled = false;
  bool backEnabled = false;

  String documentIdInput = '';
  String eventType = '';
  String statusUpload = '';
  String fileInBase64 = '';
  bool documentWillUpload = false;
  bool documentWillFinish = false;

  int step = 0;
  final ImagePicker _picker = ImagePicker();
  late File? _image = null;
  late List<FocusNode> focusNodes = List.generate(4, (index) => FocusNode());
  late Timer timer;
  String configs = '';
  String accessToken = '';
  int quality = 30;
  int sequence = 1;
  int min = 0;
  int max = 0;
  String deviceId = "";
  String deviceInfo = "";
  String osVersion = "";
  LocationData? _currentPosition;
  Location location = Location();
  String gps = "";
  String scannedText = "";
  String documentType = "";

  late Uint8List img;
  String username = '';

  late List<CreateImage?> listimage = [];
  late List<String> listtextimage = [];
  ContainerDocument tempdoc = ContainerDocument();

  @override
  void initState() {
    super.initState();
    setState(() {
      sequence = 0;
      step = 0;
      documentType = 'Container';
      eventType = 'Number';
    });
    setVisible();
    setReadOnly();
    setColor();
    setText();
    setFocus();
  }

  Future<void> getLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.DENIED) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.GRANTED) {
        return;
      }
    }

    _currentPosition = await location.getLocation();
    /*print('' +
        _currentPosition!.latitude.toString() +
        ',' +
        _currentPosition!.longitude.toString());*/
    setState(() {
      gps = (_currentPosition!.latitude.toString() +
          ',' +
          _currentPosition!.longitude.toString());
    });
  }

  Future<void> getDeviceInfo() async {
    var androidInfo = await DeviceInfoPlugin().androidInfo;
    setState(() {
      deviceId = androidInfo.androidId;
      osVersion = 'Android(' + androidInfo.version.release + ')';
      deviceInfo = androidInfo.manufacturer + '(' + androidInfo.model + ')';
    });
  }

  Future<void> showProgressImageFromCamera() async {
    ProgressDialog pr = ProgressDialog(context);
    pr = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: true, showLogs: true);
    pr.style(
        progress: 50.0,
        message: "Please wait...",
        progressWidget: Container(
            padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
        maxProgress: 100.0,
        progressTextStyle: TextStyle(
            color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600));

    await pr.show();
    timer = Timer(Duration(seconds: 3), () async {
      await pr.hide();
    });
  }

  Future<void> showProgressLoading(bool finish) async {
    ProgressDialog pr = ProgressDialog(context);
    pr = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: true, showLogs: true);
    pr.style(
        progress: 50.0,
        message: "Please wait...",
        progressWidget: Container(
            padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
        maxProgress: 100.0,
        progressTextStyle: TextStyle(
            color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600));

    if (finish == false) {
      await pr.show();
    } else {
      await pr.hide();
    }
  }

  void setVisible() {
    if (step == 0) {
      setState(() {
        documentVisible = true;
      });
    }
  }

  void setReadOnly() {
    if (step == 0) {
      setState(() {
        documentReadonly = false;
        backEnabled = false;
        takePhotoEnabled = false;
        uploadEnabled = false;
        finishEnabled = false;
        documentWillUpload = false;
        documentWillFinish = false;
      });
    } else if (step == 1) {
      setState(() {
        documentReadonly = true;
        backEnabled = true;
        takePhotoEnabled = true;
        uploadEnabled = false;
        finishEnabled = false;
      });
    } else if (step == 2) {
      setState(() {
        documentReadonly = true;
        backEnabled = true;
        takePhotoEnabled = false;
        uploadEnabled = true;
        finishEnabled = false;
      });
    } else if (step == 3) {
      if (documentWillUpload) {
        setState(() {
          documentReadonly = true;
          backEnabled = true;
          takePhotoEnabled = true;
          uploadEnabled = false;
          finishEnabled = false;
        });
      } else if (documentWillFinish) {
        setState(() {
          documentReadonly = true;
          backEnabled = true;
          takePhotoEnabled = false;
          uploadEnabled = false;
          finishEnabled = true;
        });
      }
    }
  }

  void setColor() {
    if (step == 0) {
      setState(() {
        documentColor = Color(0xFFFFFFFF);
      });
    } else if (step == 1) {
      setState(() {
        documentColor = Color(0xFFEEEEEE);
      });
    }
  }

  void setText() {
    if (step == 0) {
      setState(() {
        documentController.text = "";
        statusUpload = "No image Previews";
        scannedText = '';
        sequence = 0;
        _image = null;
        listimage = [];
        listtextimage = [];
      });
    }
  }

  void setFocus() {
    if (step == 0) {
      Future.delayed(Duration(milliseconds: 100))
          .then((_) => FocusScope.of(context).requestFocus(focusNodes[0]));
    } else if (step == 1) {
      Future.delayed(Duration(milliseconds: 100))
          .then((_) => FocusScope.of(context).requestFocus(focusNodes[1]));
    } else if (step == 2) {
      Future.delayed(Duration(milliseconds: 100))
          .then((_) => FocusScope.of(context).requestFocus(focusNodes[2]));
    } else if (step == 3) {
      Future.delayed(Duration(milliseconds: 100))
          .then((_) => FocusScope.of(context).requestFocus(focusNodes[3]));
    }
  }

  void back() {
    if (step == 1 || step == 2) {
      setState(() {
        step--;
        _image = null;
        scannedText = '';
      });
    } else if (step == 3) {
      setState(() {
        step = 0;
        _image = null;
        scannedText = '';
      });
    }
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

  Future<void> documentIDCheck() async {
    setState(() {
      documentIdInput = documentController.text;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        configs = prefs.getString('configs');
        accessToken = prefs.getString('accessToken');
      });

      var url = Uri.parse('https://' +
          configs +
          '/api/ContainerDocument/Get/' +
          documentIdInput);

      var headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer " + accessToken
      };

      http.Response response = await http.get(url, headers: headers);
      if (response.statusCode == 204) {
        setState(() {
          documentController.text = '';
          documentIdInput = '';
        });
        showErrorDialog('DocumentID Not Found!');
        setVisible();
        setReadOnly();
        setColor();
        setText();
        setFocus();
        return;
      }
      var data = json.decode(response.body);
      ContainerDocument checkAns = ContainerDocument.fromJson(data);
      setState(() {
        tempdoc = checkAns;
      });
      if (response.statusCode == 200) {
        setState(() {
          max = checkAns.containerQty!;
          step++;
        });
      } else {
        setState(() {
          documentController.text = '';
          documentIdInput = '';
        });
        showErrorDialog('DocumentID Not Found!');
      }
    } catch (e) {
      Navigator.pushReplacementNamed(context, Register.routeName);
    }
    setVisible();
    setReadOnly();
    setColor();
    setText();
    setFocus();
  }

  Future<void> _pickCamera() async {
    setState(() {
      step = 1;
    });
    try {
      PickedFile? selectedImage = await _picker.getImage(
          source: ImageSource.camera,
          imageQuality: quality,
          maxHeight: 2000,
          maxWidth: 2000);

      File? temp;
      if (selectedImage != null) {
        temp = File(selectedImage.path);
        if (selectedImage.path.isNotEmpty) {
          await showProgressLoading(false);
          await _cropImage(temp);
          await getRecognisedText(_image!);
          var tempsplit = scannedText.split("\n");
          var splitfin = tempsplit[0];
          setState(() {
            final encodedBytes = _image!.readAsBytesSync();
            fileInBase64 = base64Encode(encodedBytes);
            scannedText = splitfin;
          });
        }
      }
      if (_image != null) {
        showProgressImageFromCamera();
        setState(() {
          step++;
        });
        setVisible();
        setReadOnly();
        setColor();
        setText();
        setFocus();
      }
    } catch (e) {
      print("Error occured while PickCamera");
    }
  }

  Future<void> _cropImage(File image) async {
    await showProgressLoading(true);
    File? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatioPresets: Platform.isAndroid
            ? [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ]
            : [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio5x3,
                CropAspectRatioPreset.ratio5x4,
                CropAspectRatioPreset.ratio7x5,
                CropAspectRatioPreset.ratio16x9
              ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          title: 'Cropper',
        ));
    if (croppedFile != null) {
      setState(() {
        _image = croppedFile;
      });
    }
  }

  void _clearImage() {
    setState(() {
      _image = null;
    });
  }

  Future<void> getRecognisedText(File image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final textDetector = GoogleMlKit.vision.textDetector();
    RecognisedText recognisedText = await textDetector.processImage(inputImage);
    await textDetector.close();
    setState(() {
      scannedText = "";
    });
    for (TextBlock block in recognisedText.blocks) {
      for (TextLine line in block.lines) {
        setState(() {
          scannedText = scannedText + line.text + "\n";
        });
      }
    }

    print(scannedText);
  }

  Future<void> upload() async {
    setState(() {
      uploadEnabled = false;
      sequence++;
    });
    await showProgressLoading(false);
    await getDeviceInfo();
    await getLocation();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username');
    });

    late CreateImage? imageupload = new CreateImage();

    setState(() {
      imageupload.documentType = documentType;
      imageupload.eventType = eventType;
      imageupload.documentID = int.parse(documentIdInput);
      imageupload.sequence = sequence;
      imageupload.deviceInfo = deviceInfo;
      imageupload.osInfo = osVersion;
      imageupload.gps = gps;
      imageupload.isDeleted = false;
      imageupload.createdBy = username;
      imageupload.imageBase64 = fileInBase64;
    });

    listimage.add(imageupload);
    listtextimage.add(scannedText);

    if (sequence == max) {
      setState(() {
        _image = null;
        documentWillUpload = false;
        documentWillFinish = true;
        statusUpload = 'Upload Image Finish';
        scannedText = '';
        step++;
      });
    } else {
      setState(() {
        _image = null;
        documentWillUpload = true;
        documentWillFinish = false;
        statusUpload =
            'Upload Image : ' + sequence.toString() + ' / ' + max.toString();
        scannedText = '';
        step--;
      });
    }

    setVisible();
    setReadOnly();
    setColor();
    setText();
    setFocus();
    showProgressLoading(true);
  }

  Future<void> finish() async {
    setState(() {
      finishEnabled = false;
    });
    await showProgressLoading(false);
    //UPDATE FIELD CONTAINERDOCUMENT
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        configs = prefs.getString('configs');
        accessToken = prefs.getString('accessToken');
        username = prefs.getString('username');
      });

      var url =
          Uri.parse('https://' + configs + '/api/ContainerDocument/Update');

      var headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer " + accessToken
      };

      if (listimage.length == 1) {
        setState(() {
          //tempdoc.containerNo1 = 'test1';
          tempdoc.containerNo1 = listtextimage[0];
        });
      } else if (listimage.length == 2) {
        setState(() {
          //tempdoc.containerNo1 = 'test1';
          //tempdoc.containerNo2 = 'test2';

          tempdoc.containerNo1 = listtextimage[0];
          tempdoc.containerNo2 = listtextimage[1];
        });
      }

      var jsonBody = jsonEncode(tempdoc);
      final encoding = Encoding.getByName('utf-8');

      http.Response response = await http.post(
        url,
        headers: headers,
        body: jsonBody,
        encoding: encoding,
      );
      var data = json.decode(response.body);

      if (response.statusCode == 200) {
      } else {
        await showProgressLoading(true);
        showErrorDialog('Https Error upload');
        return;
      }
    } catch (e) {
      Navigator.pushReplacementNamed(context, Register.routeName);
    }
    //POST LIST IMAGE
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        configs = prefs.getString('configs');
        accessToken = prefs.getString('accessToken');
        username = prefs.getString('username');
      });

      var url = Uri.parse('https://' + configs + '/api/Image/CreateList');

      /*var headers = { 
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer " + accessToken
      };*/

      var headers = {'Content-Type': 'application/json'};

      var jsonBody = jsonEncode(listimage);
      final encoding = Encoding.getByName('utf-8');

      http.Response response = await http.post(
        url,
        headers: headers,
        body: jsonBody,
        encoding: encoding,
      );
      var data = json.decode(response.body);

      if (response.statusCode == 200) {
        await showProgressLoading(true);
        setState(() {
          step = 0;
          sequence = 0;
          listimage = [];
          listtextimage = [];
          scannedText = '';
        });
        showSuccessDialog('Upload Succesful');
      } else {
        await showProgressLoading(true);
        showErrorDialog('Https Error upload');
      }
    } catch (e) {
      Navigator.pushReplacementNamed(context, Register.routeName);
    }
    setVisible();
    setReadOnly();
    setColor();
    setText();
    setFocus();
  }

  Future<void> scanQR() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.QR);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    if (step == 0) {
      setState(() {
        documentController.text = barcodeScanRes;
      });
      documentIDCheck();
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
            'Container Number',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
          actions: <Widget>[
            IconButton(
                icon: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.black,
                ),
                onPressed: scanQR)
          ],
        ),
        body: Container(
            child: SingleChildScrollView(
                child: SafeArea(
                    child: Column(children: [
          SizedBox(height: 20),
          Container(
              padding: new EdgeInsets.only(
                  left: MediaQuery.of(context).size.width / 5,
                  right: MediaQuery.of(context).size.width / 5),
              child: Visibility(
                  visible: documentVisible,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    focusNode: focusNodes[0],
                    readOnly: documentReadonly,
                    textInputAction: TextInputAction.go,
                    onFieldSubmitted: (value) {
                      documentIDCheck();
                    },
                    decoration: InputDecoration(
                      //icon: const Icon(Icons.person),
                      fillColor: documentColor,
                      filled: true,
                      hintText: 'Enter Document No.',
                      labelText: 'Document Number',
                      border: OutlineInputBorder(),
                      isDense: true, // Added this
                      contentPadding: EdgeInsets.all(15), //
                    ),
                    controller: documentController,
                  ))),
          SizedBox(height: 10),
          new Center(
            child: new ButtonBar(
              mainAxisSize: MainAxisSize
                  .min, // this will take space as minimum as posible(to center)
              children: <Widget>[
                new RaisedButton(
                  color: Colors.blue,
                  child: const Text('Back',
                      style: TextStyle(
                        color: Colors.white,
                      )),
                  onPressed: backEnabled
                      ? () {
                          back();
                          setVisible();
                          setReadOnly();
                          setColor();
                          setText();
                          setFocus();
                        }
                      : null,
                ),
                new RaisedButton(
                  focusNode: focusNodes[1],
                  color: step == 1 ? Colors.green : Colors.blue,
                  child: Column(
                    children: <Widget>[Icon(Icons.add_a_photo_outlined)],
                  ),
                  onPressed: takePhotoEnabled
                      ? () {
                          _pickCamera();
                        }
                      : null,
                ),
                new RaisedButton(
                  focusNode: focusNodes[2],
                  color: step == 2 ? Colors.green : Colors.blue,
                  child: const Text('Upload',
                      style: TextStyle(
                        color: Colors.white,
                      )),
                  onPressed: uploadEnabled
                      ? () {
                          upload();
                          setVisible();
                          setReadOnly();
                          setColor();
                          setText();
                          setFocus();
                        }
                      : null,
                ),
                new RaisedButton(
                  focusNode: focusNodes[3],
                  color: step == 3 ? Colors.green : Colors.blue,
                  child: const Text('Finish',
                      style: TextStyle(
                        color: Colors.white,
                      )),
                  onPressed: finishEnabled
                      ? () {
                          finish();
                          setVisible();
                          setReadOnly();
                          setColor();
                          setText();
                          setFocus();
                        }
                      : null,
                ),
              ],
            ),
          ),
          SizedBox(height: 5),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Center(
              child: _image != null
                  ? Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        width: 225,
                        height: 225,
                        child: Image.file(
                          _image!,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Text(statusUpload),
                    ),
            )
          ]),
          SizedBox(height: 5),
          Text(scannedText,
              style: TextStyle(
                color: Colors.black,
              )),
        ])))));
  }
}
