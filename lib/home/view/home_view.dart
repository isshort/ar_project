import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:flutter/material.dart' as data;
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _platformVersion = 'Unknown';
  static const String _title = 'AR Plugin Demo';
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;
  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  @override
  void dispose() {
    super.dispose();
    arSessionManager.dispose();
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HomeView Title',
        ),
      ),
      body: Container(
        child: Stack(
          children: [
            const Text('Hello'),
            Image.asset(
              'Images/triangle.png',
              color: data.Colors.blue,
            ),
            ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            ),
            Align(
              alignment: FractionalOffset.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: onRemoveEverything,
                    child: const Text('Remove Everything'),
                  ),
                  ElevatedButton(
                    onPressed: onTakeScreenshot,
                    child: const Text('Take Screenshot'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await ArFlutterPlugin.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager.onInitialize(
          customPlaneTexturePath: 'Images/triangle.png',
          showWorldOrigin: true,
        );
    this.arObjectManager.onInitialize();

    this.arSessionManager.onPlaneOrPointTap = onPlaneOrPointTapped;
    this.arObjectManager.onNodeTap = onNodeTapped;
  }

  Future<void> onRemoveEverything() async {
    /*nodes.forEach((node) {
      this.arObjectManager.removeNode(node);
    });*/
    // anchors.forEach((anchor)
    for (final anchor in anchors) {
      arAnchorManager.removeAnchor(anchor);
    }
    anchors = [];
  }

  Future<void> onTakeScreenshot() async {
    final image = await arSessionManager.snapshot();
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(image: image, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Future<void> onNodeTapped(List<String> nodes) async {
    final number = nodes.length;
    arSessionManager.onError('Tapped $number node(s)');
  }

  Future<void> onPlaneOrPointTapped(
    List<ARHitTestResult?> hitTestResults,
  ) async {
    final singleHitTestResult = hitTestResults.firstWhere(
      (hitTestResult) => hitTestResult?.type == ARHitTestResultType.plane,
    );
    if (singleHitTestResult != null) {
      final newAnchor =
          ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
      final didAddAnchor = await arAnchorManager.addAnchor(newAnchor);
      if (didAddAnchor != null && didAddAnchor) {
        anchors.add(newAnchor);
        // Add note to anchor
        final newNode = ARNode(
          type: NodeType.webGLB,
          uri:
              'https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Duck/glTF-Binary/Duck.glb',
          scale: Vector3(0.2, 0.2, 0.2),
          position: Vector3(0, 0, 0),
          rotation: Vector4(1, 0, 0, 0),
        );
        final didAddNodeToAnchor =
            await arObjectManager.addNode(newNode, planeAnchor: newAnchor);

        if (didAddNodeToAnchor != null && didAddNodeToAnchor) {
          nodes.add(newNode);
        } else {
          arSessionManager.onError('Adding Node to Anchor failed');
        }
      } else {
        arSessionManager.onError('Adding Anchor failed');
      }
      /*
      // To add a node to the tapped position without creating an anchor, use the following code (Please mind: the function onRemoveEverything has to be adapted accordingly!):
      var newNode = ARNode(
          type: NodeType.localGLTF2,
          uri: "Models/Chicken_01/Chicken_01.gltf",
          scale: Vector3(0.2, 0.2, 0.2),
          transformation: singleHitTestResult.worldTransform);
      bool didAddWebNode = await this.arObjectManager.addNode(newNode);
      if (didAddWebNode) {
        this.nodes.add(newNode);
      }*/
    }
  }
}
