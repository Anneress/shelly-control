import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

final mqttClient = Provider<MqttClient>((ref) {
  final client =
      MqttBrowserClient("ws://192.168.188.77", Random.secure().toString());

  client.port = 8080;
  client.onConnected = () => client.subscribe("#", MqttQos.atLeastOnce);

  ref.onDispose(() => client.disconnect());

  client.connect();

  return client;
});

final mqttMessageStreamProvider =
    Provider<Stream<SimpleMqttMessage>>((ref) async* {
  final client = ref.read(mqttClient);
  await for (final messages in client.updates!) {
    for (final message in messages) {
      final res = convertMqttMessageToSimpleMqttMessage(message);
      debugPrint(res.toString());
      yield (res);
    }
  }
});

SimpleMqttMessage convertMqttMessageToSimpleMqttMessage(
  MqttReceivedMessage<MqttMessage> message,
) {
  final payload = message.payload as MqttPublishMessage;
  final pt = MqttPublishPayload.bytesToStringAsString(payload.payload.message);
  return SimpleMqttMessage(message.topic, pt);
}

final class SimpleMqttMessage extends Equatable {
  const SimpleMqttMessage(this.topic, this.payload);

  final String topic;
  final String? payload;

  @override
  List<Object?> get props => [topic, payload];

  @override
  String toString() => 'SimpleMqttMessage { topic: $topic, payload: $payload }';
}

class Shelly25 extends Equatable {
  const Shelly25({
    required this.name,
    this.isOnline = false,
    this.rollerStatus = Shelly25RollerStatus.stop,
    this.rollerPos = 0,
    this.rollerStopReason = 'normal',
    this.rollerPower = 0.0,
    this.rollerEnergy = 0.0,
    this.relayPower = 0.0,
    this.relayEnergy = 0.0,
    this.input1 = 0,
    this.input0 = 0,
    this.temperature = 0.0,
    this.temperatureF = 0.0,
    this.overtemperature = 0.0,
    this.temperatureStatus = 'normal',
    this.voltage = 0.0,
  });

  final String name;
  final bool isOnline;
  final Shelly25RollerStatus rollerStatus;
  final int rollerPos;
  final String rollerStopReason;
  final double rollerPower;
  final double rollerEnergy;
  final double relayPower;
  final double relayEnergy;
  final int input1;
  final int input0;
  final double temperature;
  final double temperatureF;
  final double overtemperature;
  final String temperatureStatus;
  final double voltage;

  @override
  List<Object?> get props => [
        name,
        isOnline,
        rollerStatus,
        rollerPos,
        rollerStopReason,
        rollerPower,
        rollerEnergy,
        relayPower,
        relayEnergy,
        input1,
        input0,
        temperature,
        temperatureF,
        overtemperature,
        temperatureStatus,
        voltage,
      ];

  Shelly25 copyWith({
    String? name,
    bool? isOnline,
    Shelly25RollerStatus? rollerStatus,
    int? rollerPos,
    String? rollerStopReason,
    double? rollerPower,
    double? rollerEnergy,
    double? relayPower,
    double? relayEnergy,
    int? input1,
    int? input0,
    double? temperature,
    double? temperatureF,
    double? overtemperature,
    String? temperatureStatus,
    double? voltage,
  }) =>
      Shelly25(
        name: name ?? this.name,
        isOnline: isOnline ?? this.isOnline,
        rollerStatus: rollerStatus ?? this.rollerStatus,
        rollerPos: rollerPos ?? this.rollerPos,
        rollerStopReason: rollerStopReason ?? this.rollerStopReason,
        rollerPower: rollerPower ?? this.rollerPower,
        rollerEnergy: rollerEnergy ?? this.rollerEnergy,
        relayPower: relayPower ?? this.relayPower,
        relayEnergy: relayEnergy ?? this.relayEnergy,
        input1: input1 ?? this.input1,
        input0: input0 ?? this.input0,
        temperature: temperature ?? this.temperature,
        temperatureF: temperatureF ?? this.temperatureF,
        overtemperature: overtemperature ?? this.overtemperature,
        temperatureStatus: temperatureStatus ?? this.temperatureStatus,
        voltage: voltage ?? this.voltage,
      );
}

class Shelly25StateNotifier extends StateNotifier<Map<String, Shelly25>> {
  Shelly25StateNotifier(this.ref) : super({}) {
    fetchShellies();
  }

  final Ref ref;

  void fetchShellies() async {
    final messagesStream = ref.read(mqttMessageStreamProvider);
    await for (final message in messagesStream) {
      if (message.topic.contains('shellies/rolladen')) {
        final splittedTopic = message.topic.split('/');
        if (splittedTopic.length > 3) {
          final name = splittedTopic[2];
          if (!state.containsKey(name)) {
            state = {...state, name: Shelly25(name: name)};
          }
          switch (splittedTopic[3]) {
            case 'online':
              state = {
                ...state,
                name: state.update(
                  name,
                  (value) => value.copyWith(
                    isOnline: bool.tryParse(message.payload ?? '') ?? false,
                  ),
                )
              };
              break;
            case 'roller':
              if (splittedTopic.length == 5) {
                state = {
                  ...state,
                  name: state.update(
                    name,
                    (value) => value.copyWith(
                      rollerStatus: Shelly25RollerStatus.values
                          .byName(message.payload ?? 'normal'),
                    ),
                  ),
                };
              } else {
                switch (splittedTopic[5]) {
                  case 'pos':
                    state = {
                      ...state,
                      name: state.update(
                        name,
                        (value) => value.copyWith(
                          rollerPos: int.tryParse(message.payload ?? '') ?? 0,
                        ),
                      ),
                    };
                    break;
                  default:
                }
              }
              break;
            default:
          }
        }
      }
    }
  }

  Future<void> openRoller(String name) async {
    return sendRollerCommand(name, 'open');
  }

  Future<void> closeRoller(String name) async {
    return sendRollerCommand(name, 'close');
  }

  Future<void> setRollerPosition(String name, int pos) async {
    return sendRollerCommand(name, pos.toString(), 'pos');
  }

  Future<void> stopRoller(String name) async {
    return sendRollerCommand(name, 'stop');
  }

  Future<void> sendRollerCommand(String name, String value,
      [String? command]) async {
    final client = ref.read(mqttClient);
    final builder = MqttClientPayloadBuilder();

    builder.addString(value);

    client.publishMessage(
      'shellies/rolladen/$name/roller/0/command${command != null ? '/$command' : ''}',
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }
}

final shelliesProvider =
    StateNotifierProvider<Shelly25StateNotifier, Map<String, Shelly25>>(
        (ref) => Shelly25StateNotifier(ref));

enum Shelly25RollerStatus { open, close, stop }

enum Shelly25RollerControl { stop, open, close }
