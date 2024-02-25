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
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${item.rollerPos}%",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Image(
                        height: 150,
                        image: AssetImage(
                          "assets/images/blinds_${item.rollerPos < 10 ? "closed" : item.rollerPos > 90 ? "opened" : "half"}.png",
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filledTonal(
                            icon: const Icon(Icons.keyboard_arrow_up_rounded),
                            onPressed: () => ref
                                .read(shelliesProvider.notifier)
                                .openRoller(item.name),
                          ),
                          Container(
                            height: 8,
                            width: 2,
                            color: Theme.of(context).dividerColor,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.pause),
                            onPressed: () => ref
                                .read(shelliesProvider.notifier)
                                .stopRoller(item.name),
                          ),
                          Container(
                            height: 8,
                            width: 2,
                            color: Theme.of(context).dividerColor,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                          ),
                          IconButton.filledTonal(
                            onPressed:
                                item.rollerStatus == Shelly25RollerStatus.close
                                    ? null
                                    : () => ref
                                        .read(shelliesProvider.notifier)
                                        .closeRoller(item.name),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onLongPress: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RollerControlPage(item: item),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class RollerControlPage extends ConsumerWidget {
  const RollerControlPage({required this.item, super.key});

  final Shelly25 item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${item.rollerPos}%",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Image(
                image: AssetImage(
                  "assets/images/blinds_${item.rollerPos < 10 ? "closed" : item.rollerPos > 90 ? "opened" : "half"}.png",
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.keyboard_arrow_up_rounded),
                    onPressed: () => ref
                        .read(shelliesProvider.notifier)
                        .openRoller(item.name),
                  ),
                  Container(
                    height: 8,
                    width: 2,
                    color: Theme.of(context).dividerColor,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.pause),
                    onPressed: () => ref
                        .read(shelliesProvider.notifier)
                        .stopRoller(item.name),
                  ),
                  Container(
                    height: 8,
                    width: 2,
                    color: Theme.of(context).dividerColor,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                  IconButton.filledTonal(
                    onPressed: item.rollerStatus == Shelly25RollerStatus.close
                        ? null
                        : () => ref
                            .read(shelliesProvider.notifier)
                            .closeRoller(item.name),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Text("Close"),
                Expanded(
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
                const Text("Open"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
