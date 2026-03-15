import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TikTokPlayerWidget extends StatefulWidget {
  const TikTokPlayerWidget({super.key, required this.url});

  final String url;

  @override
  State<TikTokPlayerWidget> createState() => _TikTokPlayerWidgetState();
}

class _TikTokPlayerWidgetState extends State<TikTokPlayerWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final embedUrl = _buildEmbedUrl(widget.url);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(embedUrl));
  }

  String _buildEmbedUrl(String url) {
    final regex = RegExp(r'/video/(\d+)');
    final match = regex.firstMatch(url);
    if (match != null) {
      return 'https://www.tiktok.com/embed/v2/${match.group(1)}';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
