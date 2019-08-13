import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:your_reward_user/bloc/base/base_bloc_state.dart';
import 'package:your_reward_user/core/injector.dart';
import 'package:your_reward_user/model/User.dart';
import 'package:your_reward_user/repository/AuthRepo.dart';
import 'package:your_reward_user/utils/app_state.dart';
import 'package:your_reward_user/utils/auth_utils.dart';
import 'package:your_reward_user/utils/pair.dart';

import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, BaseBlocState> {
  AuthRepo authRepo = injector<AuthRepo>();

  @override
  LoginState get initialState => InitialLoginState();

  @override
  Stream<BaseBlocState> mapEventToState(
    LoginEvent event,
  ) async* {
    if (event is LoginRequest) {
      yield* _handleLoginState(event.email, event.password, event.deviceId);
    } else if (event is LoggedInRequest) {
      yield LoggedInSuccess(User());
    }
    if (event is LoginFacebookRequest) {
      yield* _handleFacebookLoginRequest(event.email, event.facebookId, event.fullName, event.deviceId, event.phone);
    }
  }

  Stream<BaseBlocState> _handleLoginState(String input, String password, String deviceId) async* {
    // login with email
    if (AuthUtils.mayEmail(input)) {
      yield* _handleLoginWithEmail(input, password, deviceId);
    } else {
      //login with mobile
      yield* _handleLoginWithMobile(input, password, deviceId);
    }
  }

  Stream<BaseBlocState> _handleLoginWithEmail(String input, String password, String deviceId) async* {
    if (!AuthUtils.validateEmailValid(input)) {
      yield UIControlState.showError('Please enter the right email or phone number format.');
    } else if (!AuthUtils.validatePasswordValid(password)) {
      yield UIControlState.showError('Please enter a valid password.');
    } else {
      yield UIControlState.showLoading();
      try {
        Pair<STATE, User> result = await authRepo.loginByEmail(input, password, deviceId);
        if (result.left == STATE.SUCCESS) {
          yield LoggedInSuccess(result.right);
        } else {
          yield UIControlState.showError(result.erroMsg);
        }
      } catch (e) {
        yield UIControlState.showError(e.erroMsg);
      }
    }
  }

  Stream<BaseBlocState> _handleLoginWithMobile(String input, String password, String deviceId) async* {
    if (!AuthUtils.validateMobile(input)) {
      yield UIControlState.showError("Please enter the right email or phone number format.");
    } else if (!AuthUtils.validatePasswordValid(password)) {
      yield UIControlState.showError("Please enter a valid password.");
    } else {
      yield UIControlState.showLoading();
      try {
        Pair<STATE, User> result = await authRepo.loginByPhone(input, password, deviceId);
        if (result.left == STATE.SUCCESS) {
          yield LoggedInSuccess(result.right);
        } else {
          yield UIControlState.showError(result.erroMsg);
        }
      } catch (e) {
        yield UIControlState.showError(e.erroMsg);
      }
    }
  }

  Stream<BaseBlocState> _handleFacebookLoginRequest(
      String email, String facebookId, String fullName, String deviceId, String phone) async* {
    var result = await authRepo.registerFacebook(email, facebookId, fullName, deviceId, phone);
    if (result.right is User) {
      yield UIControlState.showLoading();
      try {
        if (result.left == FACEBOOK_STATE.SUCCESS) {
          yield LoggedInSuccess(result.right);
        } else {
          yield UIControlState.showError(result.erroMsg);
        }
      } catch (e) {
        yield UIControlState.showError(e.erroMsg);
      }
    }

    if (result.left == FACEBOOK_STATE.COMMON_ERROR) {
      yield UIControlState.showError(result.right.toString());
    }

    if (result.left == FACEBOOK_STATE.NEW_USER) {
      yield ResetState();
      yield LoggedInFacebookState();
    }
  }
}
