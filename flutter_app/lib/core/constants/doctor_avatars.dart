class DoctorAvatars {
  DoctorAvatars._();

  static const List<String> urls = [
    'https://randomuser.me/api/portraits/men/32.jpg',
    'https://randomuser.me/api/portraits/men/45.jpg',
    'https://randomuser.me/api/portraits/women/44.jpg',
    'https://randomuser.me/api/portraits/men/76.jpg',
    'https://randomuser.me/api/portraits/women/65.jpg',
    'https://randomuser.me/api/portraits/men/88.jpg',
    'https://randomuser.me/api/portraits/women/90.jpg',
    'https://randomuser.me/api/portraits/men/12.jpg',
  ];

  static String getAvatar(int index) => urls[index % urls.length];
}
