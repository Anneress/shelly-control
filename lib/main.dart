import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home/mqtt/mqtt_client.dart';

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(shelliesProvider);
    return MaterialApp(
      theme: ThemeData.light(
        useMaterial3: true,
      ),
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Smart Home'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(18),
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final item = messages.values.elementAt(index);
                return Card(
                  color: item.isOnline ? null : Theme.of(context).disabledColor,
                  child: ListTile(
                    title: Text(
                      item.name,
                      maxLines: 1,
                    ),
                    trailing: Image(
                      image: AssetImage(
                        "assets/images/blinds_${item.rollerPos < 10 ? "closed" : item.rollerPos > 90 ? "opened" : "half"}.png",
                      ),
                    ),
                    subtitle: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        switch (item.rollerStatus) {
                          Shelly25RollerStatus.close => IconButton.outlined(
                              icon: const Icon(Icons.pause),
                              color: Theme.of(context).primaryColor,
                              onPressed: () => ref
                                  .read(shelliesProvider.notifier)
                                  .stopRoller(item.name),
                            ),
                          _ => IconButton(
                              onPressed: () => ref
                                  .read(shelliesProvider.notifier)
                                  .closeRoller(item.name),
                              icon:
                                  const Icon(Icons.keyboard_arrow_down_rounded),
                            ),
                        },
                        SizedBox(
                          width: 150,
                          child: Slider(
                            label: item.rollerPos.toString(),
                            min: 0,
                            max: 100,
                            divisions: 4,
                            value: item.rollerPos.toDouble(),
                            onChangeEnd: (value) => ref
                                .read(shelliesProvider.notifier)
                                .setRollerPosition(item.name, value.toInt()),
                            onChanged: (value) => debugPrint(value.toString()),
                          ),
                        ),
                        switch (item.rollerStatus) {
                          Shelly25RollerStatus.open => IconButton.outlined(
                              icon: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.pause_rounded),
                                  Text('Auf'),
                                ],
                              ),
                              color: Theme.of(context).primaryColor,
                              onPressed: () => ref
                                  .read(shelliesProvider.notifier)
                                  .stopRoller(item.name),
                            ),
                          _ => IconButton(
                              icon: const Icon(Icons.keyboard_arrow_up_rounded),
                              onPressed: () => ref
                                  .read(shelliesProvider.notifier)
                                  .openRoller(item.name),
                            )
                        },
                      ],
                    ),
                  ),
                );
              },
            ),
          )),
    );
  }
}
