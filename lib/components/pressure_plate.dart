import 'package:flame/components.dart';
import 'package:survivor_test/survivor_test.dart';

class PressurePlate extends PositionComponent
    with HasGameReference<SurvivorTest> {
  bool inside;
  PressurePlate({position, size, required this.inside})
    : super(position: position, size: size);
}
