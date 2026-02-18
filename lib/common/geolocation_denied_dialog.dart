import 'package:flutter/cupertino.dart';
import 'package:maps_geolocator/common/app_button.dart';

class GeolocationDeniedDialog extends StatelessWidget {
  const GeolocationDeniedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Нет доступа к геолокации. Перейдите в настройки.'),

      actions: [
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Expanded(
              child: AppButton.ok(
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: 12),
            AppButton.settings(
              onPressed: () async {
                Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ],
    );
  }
}
