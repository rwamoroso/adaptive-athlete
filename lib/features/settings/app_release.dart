import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppReleaseCard extends StatefulWidget {
  const AppReleaseCard({super.key});
  @override
  State<AppReleaseCard> createState() => _AppReleaseCardState();
}

class _AppReleaseCardState extends State<AppReleaseCard> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FutureBuilder<PackageInfo>(
                future: _info,
                builder: (context, snapshot) => Text(
                    snapshot.hasData
                        ? 'Adaptive Athlete ${snapshot.data!.version} (build ${snapshot.data!.buildNumber})'
                        : 'Adaptive Athlete',
                    style: Theme.of(context).textTheme.titleMedium)),
            const ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('What changed in 1.1.0'),
                children: [
                  Text(
                      '• Safer cloud sync with a choice when device and cloud edits conflict.\n'
                      '• Ten-week plans and weekly performance now sync across devices.\n'
                      '• Running mileage excludes bike and other cardio sessions.\n'
                      '• Units, equipment, restrictions, and local-only mode survive restarts.\n'
                      '• More reliable sign-in and clearer planner validation and retry actions.\n'
                      '• Separate device-save and cloud-sync results, with the last successful sync time.'),
                ]),
          ])));
}
