import 'package:arabic_reshaper/arabic_reshaper.dart';
void main() {
  final text = 'Hello World 123';
  print(ArabicReshaper.instance.reshape(text));
}
