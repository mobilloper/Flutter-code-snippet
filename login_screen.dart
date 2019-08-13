import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:your_reward_user/entity/enums.dart';
import 'package:your_reward_user/provider/SharedPrefRepo.dart';
import 'package:your_reward_user/screen/base/BasePage.dart';
import 'package:your_reward_user/screen/base/BaseState.dart';
import 'package:your_reward_user/screen/base/ErrorMessageHandler.dart';
import 'package:your_reward_user/screen/home/v2/home_screen.dart';
import 'package:your_reward_user/screen/login/bloc/login/login_bloc.dart';
import 'package:your_reward_user/screen/login/bloc/login/login_event.dart';
import 'package:your_reward_user/screen/login/bloc/login/login_state.dart';
import 'package:your_reward_user/styles/h_fonts.dart';
import 'package:your_reward_user/styles/styles.dart';
import 'package:your_reward_user/widget/v1/YRText.dart';
import 'package:your_reward_user/widget/v2/common_button.dart';
import 'package:your_reward_user/widget/v2/textfield.dart';

import '../../../app.dart';

class LoginScreen extends BasePage {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends BaseState<LoginScreen> with ErrorMessageHandler {
  LoginBloc _loginBloc;
  String _email = "huu@example.com";
  String _password = "john.doe";
  String _token;
  String _phone, _facebookId, _deviceId, _facebookEmail, _fullname;
  FirebaseMessaging _firebaseMessaging;
  BuildContext _context;

  @override
  void initState() {
    super.initState();
    _firebaseMessaging = new FirebaseMessaging();
    _loginBloc = LoginBloc();
    SharedPrefRepo.getToken().then((token) {
      _token = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: HColors.bgColor,
      body: _buildBody(),
    );
  }

  @override
  Color getBgColor() {
    return Colors.red;
  }

  _buildBody() {
    return BlocListener(
      bloc: _loginBloc,
      listener: (context, state) {
        handleUIControlState(state);
        if (state is LoggedInSuccess) {
          super.hideLoading();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
        } else if (state is LoggedInFacebookState) {
          _showPhoneInputDialog(scaffoldKey.currentContext);
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SizedBox(
              height: 35,
            ),
            Center(
              child: Image.asset(
                'assets/images/ic_launcher.png',
                width: MediaQuery.of(context).size.width * 0.25,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(
              child: Center(
                child: YRText(
                  "YOUR REWARDS",
                  fontSize: 40,
                  textFontStyle: TextFontStyle.BOLD,
                  color: HColors.ColorSecondPrimary,
                ),
              ),
              height: 50,
            ),
            SizedBox(
              height: 15,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: YRTextField(
                  hintText: 'Enter email',
                  onTextChanged: (value) {
                    _email = value;
                  },
                  isPassword: false),
            ),
            SizedBox(
              height: 6,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: YRTextField(
                  hintText: 'Enter password',
                  onTextChanged: (value) {
                    _password = value;
                  },
                  isPassword: true),
            ),
            SizedBox(
              height: 12,
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(right: 30),
                  child: FlatButton(
                    padding: EdgeInsets.symmetric(horizontal: 0),
                    child: Text(
                      "Forgot password?",
                      style: TextStyle(color: HColors.hintTextColor, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => {Navigator.pushNamed(context, "/forgotpass")},
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(right: 30),
                  alignment: Alignment.center,
                  child: CommonButton(
                    onPressed: () => {_onSubmitLogin(context)},
                    backgroundColor: HColors.ColorPrimary,
                    textColor: HColors.black,
                    font: Hfonts.LatoSemiBold,
                    text: "Login",
                    width: MediaQuery.of(context).size.width * 0.4,
                    buttonPadding: 10,
                    radiusValue: 4,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 16,
            ),
            Row(
              children: <Widget>[
                CommonButton(
                    paddingLeft: 40,
                    paddingRight: 40,
                    roundedColor: HColors.salmon,
                    isRoundedButon: true,
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    text: "Signup",
                    icon: Icon(FontAwesomeIcons.facebookF),
                    backgroundColor: HColors.salmon,
                    font: Hfonts.LatoSemiBold,
                    textColor: HColors.salmon,
                    radiusValue: 2,
                    width: MediaQuery.of(context).size.width * 0.5,
                    buttonPadding: 0),
                CommonButton(
                    paddingLeft: 40,
                    paddingRight: 40,
                    roundedColor: HColors.deepSkyBlue,
                    isRoundedButon: true,
                    onPressed: () {
                      _onSubmitFbLogin(context);
                    },
                    text: "Facebook",
                    icon: Icon(FontAwesomeIcons.facebookF),
                    backgroundColor: HColors.ColorBgFacebook,
                    font: Hfonts.LatoSemiBold,
                    textColor: HColors.ColorBgFacebook,
                    radiusValue: 2,
                    width: MediaQuery.of(context).size.width * 0.5,
                    buttonPadding: 0),
              ],
            )
          ],
        ),
      ),
    );
  }

  _onSubmitLogin(BuildContext context) async {
    String deviceId = await getDeviceId();
    _loginBloc.dispatch(LoginRequest(email: _email, password: _password, deviceId: deviceId));
  }

  _onSubmitFbLogin(BuildContext context) async {
    try {
      var facebookSignIn = FacebookLogin();
      final result = await facebookSignIn.logInWithReadPermissions(['email', 'public_profile']);
      final token = result.accessToken.token;
      final graphResponse = await http
          .get('https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email&access_token=${"$token"}');
      final profile = json.decode(graphResponse.body);
      _fullname = profile['name'];
      _facebookEmail = profile['email'];
      _facebookId = profile['id'];
      _deviceId = await getDeviceId();
      _loginBloc.dispatch(LoginFacebookRequest(_facebookEmail, _fullname, _facebookId, _deviceId, null));
    } catch (e) {
      super.showErrorToast(_context, "Errors: ${e.toString()}");
    }
  }

  Future<String> getDeviceId() async {
    return _firebaseMessaging.getToken().then((deviceId) {
      return deviceId;
    }).catchError((err) {
      return "ERROR_GET_DEVICE_ID";
    });
  }

  Future<String> _showPhoneInputDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('One more step, please enter the phone number to complete.'),
          content: new Row(
            children: <Widget>[
              new Expanded(
                  child: new TextField(
                autofocus: true,
                decoration: new InputDecoration(labelText: 'Phone number', hintText: '0919991991'),
                onChanged: (value) {
                  _phone = value;
                },
              ))
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Confirm'),
              onPressed: () => _handleLoginWithFacebookAndSubmitedPhone(_context),
            ),
          ],
        );
      },
    );
  }

  _handleLoginWithFacebookAndSubmitedPhone(BuildContext context) {
    _loginBloc.dispatch(LoginFacebookRequest(_facebookEmail, _fullname, _facebookId, _deviceId, _phone));
    Navigator.of(context).pop(_phone);
  }
}
