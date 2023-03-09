library flutter_recaptcha_v2;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class RecaptchaV2 extends StatefulWidget {
  final String apiKey;
  final String? apiSecret;
  final String pluginURL;
  final RecaptchaV2Controller controller;
  final bool autoVerify;
  bool visibleCancelBottom;
  String textCancelButtom;

  final ValueChanged<bool>? onVerifiedSuccessfully;
  final ValueChanged<String>? onVerifiedError;
  final ValueChanged<String>? onManualVerification;

  RecaptchaV2({
    required this.apiKey,
    this.apiSecret,
    this.pluginURL = "https://recaptcha-flutter-plugin.firebaseapp.com/",
    this.visibleCancelBottom = false,
    this.textCancelButtom = "CANCEL CAPTCHA",
    RecaptchaV2Controller? controller,
    this.onVerifiedSuccessfully,
    this.onVerifiedError,
    this.onManualVerification,
    this.autoVerify = true,
  })  : controller = controller ?? RecaptchaV2Controller(),
        assert(apiKey != null, "Google ReCaptcha API KEY is missing.");

  @override
  State<StatefulWidget> createState() => _RecaptchaV2State();
}

class _RecaptchaV2State extends State<RecaptchaV2> {
  late RecaptchaV2Controller controller;
  late final WebViewController _controller;

  void verifyToken(String token) async {
    String url = "https://www.google.com/recaptcha/api/siteverify";
    http.Response response = await http.post(Uri.parse(url), body: {
      "secret": widget.apiSecret,
      "response": token,
    });

    if (response.statusCode == 200) {
      dynamic json = jsonDecode(response.body);
      if (json['success']) {
        widget.onVerifiedSuccessfully!(true);
      } else {
        widget.onVerifiedSuccessfully!(false);
        widget.onVerifiedError!(json['error-codes'].toString());
      }
    }
    controller.hide();
  }

  void onListen() {
    setState(() {
      controller.visible;
    });
  }

  @override
  void initState() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController webControll =
        WebViewController.fromPlatformCreationParams(params);

    webControll
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'RecaptchaFlutterChannel',
        onMessageReceived: (JavaScriptMessage receiver) {
          String _token = receiver.message;
          if (_token.contains("verify")) {
            _token = _token.substring(7);
          }
          if (widget.autoVerify) verifyToken(_token);
          widget.onManualVerification!(_token);
        },
      )
      ..loadRequest(Uri.parse("${widget.pluginURL}?api_key=${widget.apiKey}"))
          .then((value) => webControll.runJavaScriptReturningResult("""
      
      function createStyle() {
        var style = document.createElement('style');
        style.innerHTML = 'body { background: #fff; display: flex; align-items:center; justify-content: center; height: 100vh; overflow-x: hidden } .wave01 { top: 0; left: 0; } .wave02 { bottom: 0; right: 0; } .wave { position: fixed; z-index: -1; } #rc-imageselect {position: absolute!important; top: 0!important; left: 0!important; }';
        document.head.appendChild(style);

        document.body.insertAdjacentHTML('beforebegin', '<svg data-v-bd6b57bc="" width="555" height="460" viewBox="0 0 555 460" fill="none" xmlns="http://www.w3.org/2000/svg" class="wave wave01"><path data-v-bd6b57bc="" d="M0.0823674 388.522C-53.6566 359.613 -85.103 321.972 -84.4282 283.358C-84.2239 244.857 -51.4279 205.268 -46.2004 164.885C-40.579 124.07 -62.1323 82.0283 -47.2524 38.3134C-32.4491 -5.72038 19.1814 -51.8593 80.6096 -69.6588C142.432 -87.8903 213.975 -78.1013 277.486 -60.3104C340.921 -42.8383 395.458 -16.8193 442.183 20.1846C489.454 57.3944 528.519 106.021 477.773 133.059C426.951 159.777 286.395 165.226 225.812 215.54C165.23 265.854 184.698 361.353 156.531 399.492C128.288 437.311 53.2741 417.226 0.0823674 388.522Z" fill="#00E4A0" fill-opacity="0.05"></path></svg><svg data-v-bd6b57bc="" width="502" height="370" viewBox="0 0 502 370" fill="none" xmlns="http://www.w3.org/2000/svg" class="wave wave02"><path data-v-bd6b57bc="" d="M553.488 71.8322C607.748 99.7511 639.879 136.808 639.913 175.428C640.415 213.927 608.35 254.11 603.864 294.582C598.993 335.494 621.313 377.133 607.238 421.114C593.244 465.412 542.469 512.49 481.377 531.413C419.9 550.775 348.189 542.3 284.362 525.677C220.618 509.371 165.613 484.357 118.217 448.216C70.2711 411.88 30.3212 363.978 80.5625 336.014C130.886 308.368 271.319 300.342 330.968 248.925C390.618 197.508 369.402 102.382 396.864 63.7336C424.409 25.4024 499.779 44.109 553.488 71.8322Z" fill="#00E4A0" fill-opacity="0.05"></path></svg>');
        setInterval(function() {
          var lastChild = document.body.lastElementChild;
          lastChild.style.setProperty("position", "absolute", "important");
          lastChild.style.setProperty("left", "0px", "important");
          lastChild.style.setProperty("width", "100%", "important");
        }, 500);
      }

      window.addEventListener("load", function() {
        setTimeout(function() {
          createStyle();
        }, 400);
      });
      
  """));

    _controller = webControll;

    controller = widget.controller;
    controller.addListener(onListen);
    super.initState();
  }

  @override
  void didUpdateWidget(RecaptchaV2 oldWidget) {
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(onListen);
      controller = widget.controller;
      controller.removeListener(onListen);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.removeListener(onListen);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return controller.visible
        ? Stack(
            children: <Widget>[
              WebViewWidget(controller: _controller),
              Visibility(
                visible: widget.visibleCancelBottom,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Expanded(
                          child: InkWell(
                            child: Text(widget.textCancelButtom),
                            onTap: () {
                              controller.hide();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        : Container();
  }
}

class RecaptchaV2Controller extends ChangeNotifier {
  bool isDisposed = false;
  List<VoidCallback> _listeners = [];

  bool _visible = false;
  bool get visible => _visible;

  void show() {
    _visible = true;
    if (!isDisposed) notifyListeners();
  }

  void hide() {
    _visible = false;
    if (!isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _listeners = [];
    isDisposed = true;
    super.dispose();
  }

  @override
  void addListener(listener) {
    _listeners.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(listener) {
    _listeners.remove(listener);
    super.removeListener(listener);
  }
}
