import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double radius;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.initials,
    this.radius = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        child: initials.isNotEmpty
            ? null
            : Text(
                initials,
                style: TextStyle(
                  fontSize: radius * 0.6,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).primaryColor,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.6,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
