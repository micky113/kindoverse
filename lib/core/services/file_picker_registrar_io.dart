import 'dart:io';
import 'package:file_picker/file_picker.dart';

void registerPlatformFilePicker() {
  if (Platform.isWindows) {
    FilePicker.platform = FilePickerWindows();
  } else if (Platform.isMacOS) {
    FilePicker.platform = FilePickerMacOS();
  } else if (Platform.isLinux) {
    FilePicker.platform = FilePickerLinux();
  } else {
    FilePicker.platform = FilePickerIO();
  }
}
