/// Stub pour le web : `flutter_contacts` n'a pas d'implémentation web et son
/// import casse le bundle JS. Cette version renvoie toujours `null`.
class ContactPick {
  const ContactPick({this.name, this.phone});
  final String? name;
  final String? phone;
}

Future<ContactPick?> pickContact() async => null;
