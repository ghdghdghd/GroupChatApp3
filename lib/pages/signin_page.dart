import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:group_chat_app/helper/helper_functions.dart';
import 'package:group_chat_app/pages/home_page.dart';
import 'package:group_chat_app/pages/tabHomePage.dart';
import 'package:group_chat_app/services/auth_service.dart';
import 'package:group_chat_app/services/database_service.dart';
import 'package:group_chat_app/shared/constants.dart';
import 'package:group_chat_app/shared/loading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_page.dart';


class SignInPage extends StatefulWidget {
  final Function toggleView;
  SignInPage({required this.toggleView});

  @override
  _SignInPageState createState() => _SignInPageState();
}


class _SignInPageState extends State<SignInPage> {

  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // text field state
  String email = '';
  String password = '';
  String error = '';

  Future<Position> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    return position;
  }
  _onSignIn() async {
    print("로그인 클릭시 동작 하는 함수 _onSignIn");
    var gps = await getCurrentLocation();
    List<Placemark> mCityInfo = await placemarkFromCoordinates(gps.latitude, gps.longitude); //좌표값으로 도시정보 가져오기
    print("위치정보");
    print(mCityInfo);
    var mCityArea = mCityInfo[0].administrativeArea.toString();

    var lati = gps.latitude;
    var longi = gps.longitude;

    print(_formKey.currentState?.validate());
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await _auth.signInWithEmailAndPassword(email, password, mCityArea, lati, longi).then((result) async {
        var groupId;
        var userName;

        print("result 검증");
        print(result);


        if (result != null) {
          QuerySnapshot userInfoSnapshot = await DatabaseService(uid: '').getUserData(email);

          await HelperFunctions.saveUserLoggedInSharedPreference(true);
          await HelperFunctions.saveUserEmailSharedPreference(email);
          await HelperFunctions.saveUserNameSharedPreference(
            userInfoSnapshot.docs[0].get('fullName') // 검증요 data['fullName']
          );

          print("Signed In");
          await HelperFunctions.getUserLoggedInSharedPreference().then((value) {
            print("Logged in: $value");
          });
          await HelperFunctions.getUserEmailSharedPreference().then((value) {
            print("Email: $value");
          });
          await HelperFunctions.getUserNameSharedPreference().then((value) {
            print("Full Name: $value");
          });




          //유저이름 가져오기
          await _auth.selectUser(email, password).then((result) async {
            print("유저 정보 가져오기");
            print(result);
            userName = result;
           });

          //위치 확인 그리고 방 참가 동작 // 유저네임 그룹네임
          await _auth.selectGroupId(mCityArea).then((result) async {
             print("방그룹아이디 result 검증");
             print(result);
             if (result != null) {
               groupId = result;
             }
          });


          // UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
          // User user = result.user;
          // await DatabaseService(uid: user.uid).selectGroup(mCityArea);


         //Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(groupId: groupId, userName: userName, groupName: mCityArea)));
          Navigator.push(context, MaterialPageRoute(builder: (context) => tabHomePage(groupId: groupId, userName: userName, groupName: mCityArea)));
          //Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
        }
        else {
          setState(() {
            error = 'Error signing in!';
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ? Loading() : Scaffold(
      body: Form(
        key: _formKey,
        child: Container(
          color: Colors.transparent,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 80.0),
            children: <Widget>[
              Column(
                children: <Widget>[
                  Image.asset(
                    'assets/images/TG.png',
                    width: 100,
                    height: 100,
                  ),
                  //SizedBox(height: 16.0),
                  Text('코코뮤'),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  //Text("Create or Join Groups", style: TextStyle(color: Colors.white, fontSize: 40.0, fontWeight: FontWeight.bold)),
                
                  //SizedBox(height: 30.0),
                
                  //Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 25.0)),

                  SizedBox(height: 200.0),
                
                  TextFormField(
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                                      hintText: 'Email',
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black)
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.black)
                                      ),
                    ),

                    validator: (val) {
                      return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(val!) ? null : "Please enter a valid email";
                    },
                  
                    onChanged: (val) {
                      setState(() {
                        email = val;
                      });
                    },
                  ),
                
                  SizedBox(height: 15.0),
                
                  TextFormField(
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black)
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black)
                      ),
                    ),
                    validator: (val) => val!.length < 6 ? 'Password not strong enough' : null,
                    obscureText: true,
                    onChanged: (val) {
                      setState(() {
                        password = val;
                      });
                    },
                  ),
                
                  SizedBox(height: 20.0),
                
                  SizedBox(
                    width: double.infinity,
                    height: 50.0,
                    child: ElevatedButton(
                      // elevation: 0.0,
                      // color: Colors.blue,
                      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                      child: Text('로그인', style: TextStyle(color: Colors.black, fontSize: 16.0)),
                      onPressed: () {
                        _onSignIn();
                      }
                    ),
                  ),
                
                  SizedBox(height: 10.0),
                  
                  Text.rich(
                    TextSpan(
                      text: "계정이 없으신가요? ",
                      style: TextStyle(color: Colors.black, fontSize: 14.0),
                      children: <TextSpan>[
                        TextSpan(
                          text: '간편가입하기',
                          style: TextStyle(
                            color: Colors.black,
                            decoration: TextDecoration.underline
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () {
                            widget.toggleView();
                          },
                        ),
                      ],
                    ),
                  ),
                
                  SizedBox(height: 10.0),
                
                  Text(error, style: TextStyle(color: Colors.red, fontSize: 14.0)),
                ],
              ),
            ],
          ),
        ),
      )
    );
  }
}


// class tabHome extends StatefulWidget {
//   const tabHome({Key? key}) : super(key: key);
//
//
//   @override
//   State<tabHome> createState() => _tabHomeState();
// }
//
// class _tabHomeState extends State<tabHome> {
//   final _usernameController = TextEditingController();
//   final _passwordController = TextEditingController();
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: ListView(
//           padding: EdgeInsets.symmetric(horizontal: 24.0),
//           children: <Widget>[
//             SizedBox(height: 100.0),
//             Column(
//               children: <Widget>[
//                 Image.asset(
//                   'assets/images/TG.png',
//
//
//                   width: 100,
//                   height: 100,
//                 ),
//                 SizedBox(height: 16.0),
//                 Text('코코뮤'),
//               ],
//             ),
//             SizedBox(height: 200.0),
//             // TextField(
//             //   controller: _usernameController,
//             //   decoration: InputDecoration(
//             //     filled: true,
//             //     labelText: 'Username',
//             //   ),
//             // ),
//             SizedBox(height: 12.0),
//             // TextField(
//             //   controller: _passwordController,
//             //   decoration: InputDecoration(
//             //     filled: true,
//             //     labelText: 'Password',
//             //   ),
//             //   obscureText: true,
//             // ),
//             SizedBox(height: 10.0,),
//
//             ElevatedButton(
//               style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.green)),
//               child: Text('네이버 로그인'),
//               onPressed: () {
//                 _usernameController.clear();
//                 _passwordController.clear();
//               },
//             ),
//             SizedBox(height: 10.0,),
//             ElevatedButton(
//               style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.yellow)),
//               child: Text('카카오 로그인'),
//               onPressed: () {
//                 _usernameController.clear();
//                 _passwordController.clear();
//               },
//             ),
//             ButtonBar(
//               children: <Widget>[
//                 //   FlatButton(
//                 //   child: Text('계정 찾기'),
//                 //   onPressed: () {
//                 //     Navigator.push(
//                 //         context,
//                 //         MaterialPageRoute(builder: (context) => memberFind())
//                 //     );
//                 //   },
//                 // ),
//               ],
//             ),
//
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => Home()),
//           );
//         },
//
//       ),
//     );
//   }
// }
