import 'package:firebase_auth/firebase_auth.dart';
import 'package:group_chat_app/helper/helper_functions.dart';
import 'package:group_chat_app/models/users.dart';
import 'package:group_chat_app/services/database_service.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;


  // create user object based on FirebaseUser
  Users? _userFromFirebaseUser(User user) {
    return (user != null) ? Users(uid: user.uid) : null;
  }


  // sign in with email and password
  Future signInWithEmailAndPassword(String email, String password, String mCityArea, double latitude, double longitude) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      print("여기는 signInWithEmailAndPassword");
      User? user = result.user;
      print(user);
      print(user!.uid);

      await DatabaseService(uid: user!.uid).updateLocation(mCityArea, latitude, longitude); //위치 업데이트

      return _userFromFirebaseUser(user);
    } catch(e) {
      print(e.toString());
      return null;
    }
  }
  // 유저 정보 가져오기
  Future selectUser(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      print("여기는 selectUser");
      print(result);
      User? user = result.user;
      print(user);
      print(user!.uid);

      var userInfo = await DatabaseService(uid: user.uid).selectUser(); //유저 정보 가져오기
      var fullName = userInfo['fullName'];

      print("여기 유저풀네임은.......");
      print(fullName);

      return fullName;
    } catch(e) {
      print(e.toString());
      return null;
    }
  }

  // 위치정보로 그룹(방) 정보 가져오기
  Future selectGroupId(String mCityArea) async {
    try {
      // UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      // print(" 여기는 signInWithEmailAndPassword");
      // User user = result.user;
      // print(user);
      var seoul = '2uZto4t4Fer3zk5Y4YcI';

      print("여기 그룹아이디는 1");
      var result = await DatabaseService(uid: seoul).selectGroupId(); //위치 업데이트
      var groupId = result['groupId'];
      print("여기 그룹아이디는 2");
      print(groupId);


     return groupId;


    } catch(e) {
      print(e.toString());
      return null;
    }
  }



  // register with email and password
  Future registerWithEmailAndPassword(String fullName, String email, String password, String mCityArea, double latitude, double longitude) async {
    print("12341234123412341243");
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      print("4444444444445444444");
      print(result);
      User? user = result.user;
      print("6666666666666666");

      // Create a new document for the user with uid
      await DatabaseService(uid: user!.uid).updateUserData(fullName, email, password, mCityArea, latitude, longitude);
      return _userFromFirebaseUser(user);
    } catch(e) {
      print("걍 에러@!!!!");
      print(e.toString());
      return null;
    }
  }

  //sign out
  Future signOut() async {
    try {
      await HelperFunctions.saveUserLoggedInSharedPreference(false);
      await HelperFunctions.saveUserEmailSharedPreference('');
      await HelperFunctions.saveUserNameSharedPreference('');

      return await _auth.signOut().whenComplete(() async {
        print("Logged out");
        await HelperFunctions.getUserLoggedInSharedPreference().then((value) {
          print("Logged in: $value");
        });
        await HelperFunctions.getUserEmailSharedPreference().then((value) {
          print("Email: $value");
        });
        await HelperFunctions.getUserNameSharedPreference().then((value) {
          print("Full Name: $value");
        });
      });
    } catch(e) {
      print(e.toString());
      return null;
    }
  }
}