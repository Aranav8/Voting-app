import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SocialMediaLink {
  final String platform;
  final String url;
  final String iconPath;

  SocialMediaLink({
    required this.platform,
    required this.url,
    required this.iconPath,
  });

  String get username {
    final Uri uri = Uri.parse(url);
    switch (platform.toLowerCase()) {
      case 'facebook':
        return uri.pathSegments.isNotEmpty ? '@${uri.pathSegments.last}' : url;
      case 'instagram':
        return uri.pathSegments.isNotEmpty ? '@${uri.pathSegments.last}' : url;
      case 'youtube':
        return uri.pathSegments.isNotEmpty ? '@${uri.pathSegments.last}' : url;
      case 'linkedin':
        return uri.pathSegments.isNotEmpty ? '@${uri.pathSegments.last}' : url;
      default:
        return url;
    }
  }

  String get formattedUrl {
    String processedUrl = url.trim();
    if (!processedUrl.startsWith('http://') &&
        !processedUrl.startsWith('https://')) {
      processedUrl = 'https://$processedUrl';
    }

    // Add www. if not present (helps with some Android issues)
    if (!processedUrl.contains('www.')) {
      processedUrl = processedUrl.replaceFirst('https://', 'https://www.');
    }

    return processedUrl;
  }
}

class SocialMediaSection extends StatelessWidget {
  final List<SocialMediaLink> socialLinks;

  const SocialMediaSection({
    Key? key,
    required this.socialLinks,
  }) : super(key: key);

  Future<void> _launchURL(
      BuildContext context, String platform, String urlString) async {
    try {
      // Format URL based on platform
      String formattedUrl = urlString;

      // Add platform-specific formatting
      switch (platform.toLowerCase()) {
        case 'facebook':
          if (!formattedUrl.contains('www.facebook.com')) {
            formattedUrl =
                'https://www.facebook.com/${formattedUrl.split('/').last}';
          }
          break;
        case 'instagram':
          if (!formattedUrl.contains('www.instagram.com')) {
            formattedUrl =
                'https://www.instagram.com/${formattedUrl.split('/').last}';
          }
          break;
        case 'youtube':
          if (!formattedUrl.contains('www.youtube.com')) {
            formattedUrl =
                'https://www.youtube.com/${formattedUrl.split('/').last}';
          }
          break;
        case 'linkedin':
          if (!formattedUrl.contains('www.linkedin.com')) {
            formattedUrl =
                'https://www.linkedin.com/in/${formattedUrl.split('/').last}';
          }
          break;
      }

      if (await canLaunchUrlString(formattedUrl)) {
        final bool launched = await launchUrlString(
          formattedUrl,
          mode: LaunchMode.externalApplication,
        );

        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open $platform profile'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open $platform profile'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening $platform profile'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Social Media',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 10),
        ...socialLinks.map((link) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: InkWell(
                onTap: () =>
                    _launchURL(context, link.platform, link.formattedUrl),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      link.iconPath,
                      height: 35,
                    ),
                    const SizedBox(width: 20),
                    Text(
                      link.username,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
