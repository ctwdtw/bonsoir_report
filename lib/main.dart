import 'package:bonsoir/bonsoir.dart'; // 4.0.0
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

final logger = Logger();

void main() {
  runApp(const BonsoirApp());
}

class BonsoirApp extends StatelessWidget {
  const BonsoirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Simple Flutter App'),
        ),
        body: FutureBuilder(
          future: BonsoirDiscoverRepo.instance.init(),
          builder: (ctx, snapShot) {
            if (snapShot.connectionState == ConnectionState.done) {
              return const Text('discovering');
            } else {
              return const Text('waiting');
            }
          },
        ),
      ),
    );
  }
}

class BonsoirDiscoverRepo {
  static BonsoirDiscoverRepo get instance {
    _instance ??= BonsoirDiscoverRepo._internal();
    return _instance!;
  }

  static BonsoirDiscoverRepo? _instance;
  BonsoirDiscovery? _discover;

  BonsoirDiscoverRepo._internal();

  Future<void> init() async {
    if (_discover == null) {
      _discover = BonsoirDiscovery(type: '_http._tcp');
      await _discover!.ready;
      if (_discover!.eventStream == null) {
        return;
      }
      _discover!.eventStream!
          .where((event) => event.service?.name.contains('IGD-') ?? false)
          .listen(
            (event) async {
          if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
            event.service?.resolve(_discover!.serviceResolver);
          } else if (event.type ==
              BonsoirDiscoveryEventType.discoveryServiceResolved) {
            logger.d('resolve: ${event.service?.toJson()}');
          } else if (event.type ==
              BonsoirDiscoveryEventType.discoveryServiceLost) {
            logger.d('lost: ${event.service?.toJson()}');
          }
        },
      );
      await _discover!.start();
      logger.d('start discover and put event to lower stream');
    } else {
      logger.d('already start discover');
    }
  }
}