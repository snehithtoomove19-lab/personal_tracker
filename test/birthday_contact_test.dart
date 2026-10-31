import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/models/birthday_contact.dart';

void main() {
  test('legacy birthday contacts load without contact details', () {
    final contact = BirthdayContact.fromJson({
      'id': 'legacy',
      'name': 'Alex',
      'relation': 'Friend',
      'date': '2000-05-10T00:00:00.000',
    });

    expect(contact.phoneNumber, isEmpty);
    expect(contact.email, isEmpty);
  });

  test('birthday contact saves and loads phone number and email', () {
    final contact = BirthdayContact(
      id: 'contact-1',
      name: 'Alex',
      relation: 'Friend',
      date: DateTime(2000, 5, 10),
      phoneNumber: '+1 555 123 4567',
      email: 'alex@example.com',
    );

    final restored = BirthdayContact.fromJson(contact.toJson());

    expect(restored.phoneNumber, contact.phoneNumber);
    expect(restored.email, contact.email);
  });
}
