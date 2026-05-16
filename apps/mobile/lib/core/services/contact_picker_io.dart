import 'package:flutter_contacts/flutter_contacts.dart';

class ContactPick {
  const ContactPick({this.name, this.phone});
  final String? name;
  final String? phone;
}

/// Ouvre le picker système (Android/iOS) et renvoie nom + premier numéro.
/// Renvoie `null` si l'utilisateur annule.
Future<ContactPick?> pickContact() async {
  final c = await FlutterContacts.openExternalPick();
  if (c == null) return null;
  final name = c.displayName.trim();
  final phone = c.phones.isNotEmpty ? c.phones.first.number.trim() : '';
  return ContactPick(
    name: name.isEmpty ? null : name,
    phone: phone.isEmpty ? null : phone,
  );
}
