import 'package:file_picker/file_picker.dart';

import 'file_picker_registrar_stub.dart'
    if (dart.library.js_interop) 'file_picker_registrar_web.dart'
    if (dart.library.io) 'file_picker_registrar_io.dart';

/// Ensures [FilePicker.platform] is initialized so that accessing it never
/// throws a `LateInitializationError` (e.g. when hot-reloading/restarting
/// before the generated plugin registrant has executed).
FilePicker ensureFilePickerInitialized() {
  try {
    return FilePicker.platform;
  } catch (_) {
    registerPlatformFilePicker();
    return FilePicker.platform;
  }
}
