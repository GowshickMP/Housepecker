// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:Housepecker/data/Repositories/auth_repository.dart';
import 'package:Housepecker/utils/hive_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginInProgress extends LoginState {}

class LoginSuccess extends LoginState {
  final bool isProfileCompleted;
  LoginSuccess({
    required this.isProfileCompleted,
  });
}

class LoginFailure extends LoginState {
  final String errorMessage;
  LoginFailure(this.errorMessage);
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitial());

  final AuthRepository _authRepository = AuthRepository();
  bool isProfileIsCompleted = false;

  void login(
      {required String phoneNumber,
      required String otp}) async {
    try {
      emit(LoginInProgress());
      Map<String, dynamic> result = await _authRepository.loginWithApi(
        phone: phoneNumber,
        otp: otp,
      );

      ///Storing data to local database {HIVE}
      HiveUtils.setJWT(result['token']);

      if (result['data']['name'] == "" && result['data']['email'] == "") {
        HiveUtils.setProfileNotCompleted();
        isProfileIsCompleted = false;
        var data = result['data'];
        data['countryCode'] = '+91';
        HiveUtils.setUserData(data);
      } else {
        isProfileIsCompleted = true;
        var data = result['data'];
        data['countryCode'] = '+91';
        HiveUtils.setUserData(data);
      }

      emit(LoginSuccess(isProfileCompleted: isProfileIsCompleted));
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }
}
