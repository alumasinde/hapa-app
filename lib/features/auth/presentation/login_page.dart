import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override ConsumerState<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false, _obscure = true;
  @override void dispose(){_email.dispose();_password.dispose();super.dispose();}
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(()=>_loading=true);
    try {
      await ref.read(authControllerProvider.notifier).login(email:_email.text.trim(),password:_password.text);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to sign in. Check your details and try again.')));
    } finally { if(mounted)setState(()=>_loading=false); }
  }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth:460), child: Form(key:_formKey, child: Column(crossAxisAlignment:CrossAxisAlignment.stretch, children:[
    const Icon(Icons.location_on_outlined,size:44),
    const SizedBox(height:24),
    Text('Welcome to Hapa',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w700)),
    const SizedBox(height:8),
    const Text('Sign in to report and follow incidents around you.'),
    const SizedBox(height:32),
    TextFormField(controller:_email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Email',prefixIcon:Icon(Icons.email_outlined)),validator:(v)=>v==null||!v.contains('@')?'Enter a valid email':null),
    const SizedBox(height:16),
    TextFormField(controller:_password,obscureText:_obscure,decoration:InputDecoration(labelText:'Password',prefixIcon:const Icon(Icons.lock_outline),suffixIcon:IconButton(onPressed:()=>setState(()=>_obscure=!_obscure),icon:Icon(_obscure?Icons.visibility_outlined:Icons.visibility_off_outlined))),validator:(v)=>v==null||v.length<8?'Password must be at least 8 characters':null),
    const SizedBox(height:24),
    FilledButton(onPressed:_loading?null:_submit,child:Padding(padding:const EdgeInsets.symmetric(vertical:14),child:_loading?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)):const Text('Sign in'))),
    const SizedBox(height:12),
    TextButton(onPressed:_loading?null:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const RegisterPage())),child:const Text('Create a new account')),
  ]))))));
}