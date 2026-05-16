// Façade plateforme-aware pour le picker de contacts.
// - Web → stub (`flutter_contacts` ne supporte pas le web).
// - Mobile/desktop → implémentation `flutter_contacts`.
export 'contact_picker_stub.dart'
    if (dart.library.io) 'contact_picker_io.dart';
