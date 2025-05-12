import 'dart:async';
import 'dart:math' as math;

import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter/material.dart' as material show Colors;
import 'package:flutter/material.dart' hide Colors;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lidar_scanner/feature/ar_physics/cubit/ar_physics_cubit.dart';
import 'package:lidar_scanner/feature/ar_physics/cubit/ar_physics_state.dart';
import 'package:lidar_scanner/feature/ar_physics/mixin/ar_physics_mixin.dart';
import 'package:vector_math/vector_math_64.dart';

class ArPhysicsView extends StatefulWidget {
  const ArPhysicsView({super.key});

  @override
  State<ArPhysicsView> createState() => _ArPhysicsViewState();
}

class _ArPhysicsViewState extends State<ArPhysicsView> with ArPhysicsMixin {
  late ARKitController _arKitController;
  Timer? _objectSpawnTimer;
  final _random = math.Random();
  final Map<String, ARKitNode> _arNodes = {};

  @override
  void initState() {
    super.initState();
    arPhysicsCubit.initialize();
  }

  @override
  void dispose() {
    _objectSpawnTimer?.cancel();
    _arKitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Physics'),
      ),
      body: Stack(
        children: [
          ARKitSceneView(
            onARKitViewCreated: _onARKitViewCreated,
            planeDetection: ARPlaneDetection.horizontalAndVertical,
            enableTapRecognizer: true,
          ),
          _buildUI(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildUI() {
    return BlocBuilder<ArPhysicsCubit, ArPhysicsState>(
      bloc: arPhysicsCubit,
      builder: (context, state) {
        if (!state.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!state.isPlaneDetected) {
          return const Center(
            child: Text(
              'Yüzeyleri taramak için etrafınıza bakın',
              style: TextStyle(color: material.Colors.white),
            ),
          );
        }

        return Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: material.Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Nesneler: ${state.physicsObjects.length}',
              style: const TextStyle(color: material.Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButtons() {
    return BlocBuilder<ArPhysicsCubit, ArPhysicsState>(
      bloc: arPhysicsCubit,
      builder: (context, state) {
        if (!state.isInitialized || !state.isPlaneDetected) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'add_object',
              onPressed: _addRandomObject,
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'toggle_rain',
              onPressed: _toggleObjectRain,
              child: Icon(
                  _objectSpawnTimer == null ? Icons.play_arrow : Icons.stop),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'clear_objects',
              onPressed: () {
                _objectSpawnTimer?.cancel();
                _objectSpawnTimer = null;
                arPhysicsCubit.clearAllObjects();
                // Tüm nesneleri temizle
                _arNodes.forEach((_, node) {
                  _arKitController.remove(node.name);
                });
                _arNodes.clear();
              },
              child: const Icon(Icons.delete),
            ),
          ],
        );
      },
    );
  }

  void _onARKitViewCreated(ARKitController controller) {
    _arKitController = controller;

    // Düzlem algılandığında bildirim almak için
    _arKitController.onAddNodeForAnchor = _handleAddAnchor;

    // Ekrana dokunma olayını işlemek için
    _arKitController.onNodeTap = (nodes) => _handleTap(nodes);

    // AR görünümü hazır olduğunda cubit'e bildir
    arPhysicsCubit.startPhysicsSimulation();

    // State değişikliklerini dinleyerek AR nesnelerini güncelle
    arPhysicsCubit.stream.listen((state) {
      if (mounted) {
        _updateArObjects(state.physicsObjects);
      }
    });
  }

  void _handleAddAnchor(ARKitAnchor anchor) {
    if (anchor is ARKitPlaneAnchor) {
      arPhysicsCubit.onPlaneDetected();

      // Algılanan düzlem için fiziksel bir zemin ekle
      _addPlane(anchor);
    }
  }

  void _addPlane(ARKitPlaneAnchor anchor) {
    final plane = ARKitPlane(
      width: anchor.extent.x,
      height: anchor.extent.z,
      materials: [
        ARKitMaterial(
          transparency: 0.5,
          diffuse: ARKitMaterialProperty.color(
            material.Colors.white.withOpacity(0.2),
          ),
        )
      ],
    );

    final node = ARKitNode(
      geometry: plane,
      physicsBody: ARKitPhysicsBody(
        ARKitPhysicsBodyType.staticType,
        categoryBitMask: 2, // Düzlem kategorisi
      ),
      position: Vector3(anchor.center.x, anchor.center.y, anchor.center.z),
      rotation: Vector4(1, 0, 0, -math.pi / 2),
    );

    _arKitController.add(node, parentNodeName: anchor.nodeName);
  }

  void _handleTap(List<String> nodeNames) {
    if (nodeNames.isEmpty) return;

    // Ekranın ortasına yeni bir nesne ekle
    _addRandomObject();
  }

  void _addRandomObject() {
    // Kameranın önünde rastgele bir pozisyon
    final position = Vector3(
      (_random.nextDouble() - 0.5) * 2, // -1 ile 1 arasında
      1.5 + _random.nextDouble(), // 1.5 ile 2.5 arasında (yerden yüksekte)
      -2 - _random.nextDouble() * 2, // -2 ile -4 arasında (önümüzde)
    );

    // Fizik nesnesi ekle
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _addPhysicsObject(id, position);

    // Cubit'e bildir
    arPhysicsCubit.addRandomObject(position: position);
  }

  void _addPhysicsObject(String id, Vector3 position) {
    // Rastgele şekil seç (küre veya küp)
    final isBox = _random.nextBool();
    final randomColor = material
        .Colors.primaries[_random.nextInt(material.Colors.primaries.length)];
    final objectMaterial = ARKitMaterial(
      diffuse: ARKitMaterialProperty.color(randomColor),
    );

    final geometry = isBox
        ? ARKitBox(
            width: 0.2,
            height: 0.2,
            length: 0.2,
            materials: [objectMaterial],
          )
        : ARKitSphere(
            radius: 0.1,
            materials: [objectMaterial],
          );

    final node = ARKitNode(
      name: id,
      geometry: geometry,
      position: position,
      physicsBody: ARKitPhysicsBody(
        ARKitPhysicsBodyType.dynamicType,
        categoryBitMask: 1, // Nesne kategorisi
      ),
    );

    _arKitController.add(node);
    _arNodes[id] = node;
  }

  void _toggleObjectRain() {
    if (_objectSpawnTimer != null) {
      _objectSpawnTimer!.cancel();
      _objectSpawnTimer = null;
      setState(() {});
      return;
    }

    // Her 0.5 saniyede bir yeni nesne ekle
    _objectSpawnTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) => _addRandomObject(),
    );
    setState(() {});
  }

  // Fizik nesnelerini AR görünümünde güncelle
  void _updateArObjects(List<PhysicsObject> physicsObjects) {
    // Yeni eklenen nesneleri kontrol et
    for (final object in physicsObjects) {
      if (!_arNodes.containsKey(object.id)) {
        _addPhysicsObject(
            object.id,
            Vector3(
              object.position.x,
              object.position.y,
              object.position.z,
            ));
      } else {
        // Var olan nesnelerin pozisyonunu güncelle
        final node = _arNodes[object.id]!;
        _arKitController.removeAnchor(node.name);
        _addPhysicsObject(
            object.id,
            Vector3(
              object.position.x,
              object.position.y,
              object.position.z,
            ));
      }
    }

    // Silinen nesneleri kontrol et
    final objectIds = physicsObjects.map((e) => e.id).toSet();
    final nodesToRemove =
        _arNodes.keys.where((id) => !objectIds.contains(id)).toList();

    for (final id in nodesToRemove) {
      final node = _arNodes[id]!;
      _arKitController.remove(node.name);
      _arNodes.remove(id);
    }
  }
}
