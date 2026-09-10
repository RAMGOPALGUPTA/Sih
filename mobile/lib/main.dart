import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

Future<void> main() async { WidgetsFlutterBinding.ensureInitialized(); final cams=await availableCameras(); runApp(App(camera:cams.first)); }
class App extends StatelessWidget { final CameraDescription camera; const App({super.key,required this.camera}); @override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,theme:ThemeData(useMaterial3:true),home:Capture(camera:camera)); }
class Capture extends StatefulWidget { final CameraDescription camera; const Capture({super.key,required this.camera}); @override State<Capture> createState()=>_CaptureState(); }
class _CaptureState extends State<Capture>{ late CameraController cam; String status='Ready'; bool busy=false;
 @override void initState(){super.initState(); cam=CameraController(widget.camera,ResolutionPreset.high,enableAudio:false); cam.initialize().then((_){if(mounted)setState((){});});}
 Future<void> take() async { if(busy||!cam.value.isInitialized)return; setState(()=>busy=true); try{ final p=await cam.takePicture(); final bytes=await File(p.path).readAsBytes(); final hash=sha256.convert(bytes).toString(); Position? pos; try{pos=await Geolocator.getCurrentPosition();}catch(_){ } final id=DateTime.now().microsecondsSinceEpoch.toString(); final payload={'id':id,'operator_id':'demo-operator','classification':'inconclusive','confidence':0.0,'latitude':pos?.latitude,'longitude':pos?.longitude,'captured_at':DateTime.now().toUtc().toIso8601String(),'model_version':'untrained','app_version':'1.0.0','image_sha256':hash}; final r=await http.post(Uri.parse('http://10.0.2.2:8000/api/v1/cases'),headers:{'content-type':'application/json'},body:jsonEncode(payload)); setState(()=>status=r.statusCode<300?'Saved: $hash':'Offline record: $hash'); }catch(e){setState(()=>status='Capture failed: $e');}finally{setState(()=>busy=false);} }
 @override Widget build(BuildContext c){if(!cam.value.isInitialized)return const Scaffold(body:Center(child:CircularProgressIndicator()));return Scaffold(appBar:AppBar(title:const Text('Field Test Companion')),body:Stack(fit:StackFit.expand,children:[CameraPreview(cam),Positioned(bottom:30,left:24,right:24,child:FilledButton.icon(onPressed:take,icon:const Icon(Icons.camera),label:Text(busy?'Processing…':'Capture test'))),Positioned(top:20,left:12,right:12,child:Card(child:Padding(padding:const EdgeInsets.all(10),child:Text(status))))]));}
 @override void dispose(){cam.dispose();super.dispose();}}
