import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:form_bloc/form_bloc.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MaterialApp(home: SignUpScreen()));

class SignUpFormBloc extends FormBloc<String, String> {
  final emailField = TextFieldBloc(
    validators: [Validators.email],
  );

  final passwordField = TextFieldBloc(
    validators: [Validators.passwordMin6Chars],
  );

  final postcodeField = TextFieldBloc(
    asyncValidatorDebounceTime: Duration(milliseconds: 500),
  );

  @override
  List<FieldBloc> get fieldBlocs => [emailField, passwordField, postcodeField];

  SignUpFormBloc() {
    postcodeField.addAsyncValidators([_isValidPostcode]);
  }

  Future<String> _isValidPostcode(String postcode) async {
    try {
      final response =
      await http.get('https://api.postcodes.io/postcodes/$postcode');

      print(response.body);
      if (response.statusCode != 200) {
        return json.decode(response.body)['error'];
      }
    } catch (e) {
      return 'There is no Internet connection';
    }

    return null;
  }

  @override
  Stream<FormBlocState<String, String>> onSubmitting() async* {
    // Form logic...
    try {
      // Get the fields values:
      print(postcodeField.value);
      print(emailField.value);
      print(postcodeField.value);
      await Future<void>.delayed(Duration(seconds: 2));
      yield currentState.toSuccess();
    } catch (e) {
      yield currentState.toFailure(
          'Fake error, please continue testing the async validation.');
    }
  }
}

class SignUpScreen extends StatefulWidget {
  SignUpScreen({Key key}) : super(key: key);

  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  SignUpFormBloc _simpleFormBloc;

  @override
  void initState() {
    super.initState();
    _simpleFormBloc = SignUpFormBloc();
  }

  @override
  void dispose() {
    _simpleFormBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign up')),
      body: FormBlocListener(
        formBloc: _simpleFormBloc,
        onSubmitting: (context, state) {
          // Show the progress dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => WillPopScope(
              onWillPop: () async => false,
              child: Center(
                child: Card(
                  child: Container(
                    width: 80,
                    height: 80,
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          );
        },
        onSuccess: (context, state) {
          // Hide the progress dialog
          Navigator.of(context).pop();
          // Navigate to success screen
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => SuccessScreen()));
        },
        onFailure: (context, state) {
          // Hide the progress dialog
          Navigator.of(context).pop();
          // Show snackbar with the error
          Scaffold.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failureResponse),
              backgroundColor: Colors.red[300],
            ),
          );
        },
        child: ListView(
          children: <Widget>[
            TextFieldBlocBuilder(
              textFieldBloc: _simpleFormBloc.emailField,
              decoration: InputDecoration(labelText: 'Email ID'),
              maxLength: 32,
              keyboardType: TextInputType.emailAddress,
            ),
            TextFieldBlocBuilder(
              textFieldBloc: _simpleFormBloc.passwordField,
              decoration: InputDecoration(labelText: 'Password'),
              maxLength: 32,
            ),
            TextFieldBlocBuilder(
              textFieldBloc: _simpleFormBloc.postcodeField,
              suffixButton: SuffixButton.circularIndicatorWhenIsAsyncValidating,
              decoration: InputDecoration(labelText: 'Postcode'),
              maxLength: 32,
              errorBuilder: (context, error) {
                // Here you can map your error codes
                // if you want to use Localizations
                switch (error) {
                  case ValidatorsError.requiredTextFieldBloc:
                    return 'Please enter a postcode.';
                    break;
                  default:
                    return error;
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: RaisedButton(
                onPressed: _simpleFormBloc.submit,
                child: Center(child: Text('SIGN UP')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[300],
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Icon(
                Icons.sentiment_satisfied,
                size: 100,
              ),
              RaisedButton(
                color: Colors.green[100],
                child: Text('Go to home'),
                onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => SignUpScreen())),
              )
            ],
          ),
        ),
      ),
    );
  }
}
