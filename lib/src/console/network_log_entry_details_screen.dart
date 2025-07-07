import 'package:flutter/material.dart';
import 'package:logarte/logarte.dart';
import 'package:logarte/src/console/logarte_theme_wrapper.dart';
import 'package:logarte/src/extensions/entry_extensions.dart';
import 'package:logarte/src/extensions/object_extensions.dart';
import 'package:logarte/src/extensions/string_extensions.dart';

enum MenuItem { normal, curl }

class NetworkLogEntryDetailsScreen extends StatelessWidget {
  final NetworkLogarteEntry entry;
  final Logarte instance;

  const NetworkLogEntryDetailsScreen(
    this.entry, {
    Key? key,
    required this.instance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LogarteThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: Navigator.of(context).pop,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            '${entry.asReadableDuration}, ${entry.response.body.toString().asReadableSize}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: false,
          actions: [
            PopupMenuButton<MenuItem>(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy),
              onSelected: (item) {
                switch (item) {
                  case MenuItem.normal:
                    entry.toString().copyToClipboard(context);
                    break;
                  case MenuItem.curl:
                    entry.curlCommand().copyToClipboard(context);
                    break;
                }
              },
              itemBuilder: (_) => <PopupMenuEntry<MenuItem>>[
                const PopupMenuItem<MenuItem>(
                  value: MenuItem.normal,
                  child: Text('Copy'),
                ),
                const PopupMenuItem<MenuItem>(
                  value: MenuItem.curl,
                  child: Text('Copy as cURL'),
                ),
              ],
            ),
            PopupMenuButton<MenuItem>(
              tooltip: 'Share',
              icon: const Icon(Icons.share),
              onSelected: (item) {
                switch (item) {
                  case MenuItem.normal:
                    instance.onShare?.call(entry.toString());
                    break;
                  case MenuItem.curl:
                    instance.onShare?.call(entry.curlCommand());
                    break;
                }
              },
              itemBuilder: (_) => <PopupMenuEntry<MenuItem>>[
                const PopupMenuItem<MenuItem>(
                  value: MenuItem.normal,
                  child: Text('Share'),
                ),
                const PopupMenuItem<MenuItem>(
                  value: MenuItem.curl,
                  child: Text('Share as cURL'),
                ),
              ],
            ),
            const SizedBox(width: 12.0),
          ],
        ),
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Request'),
                  Tab(text: 'Response'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    Scrollbar(
                      child: ListView(
                        children: [
                          SelectableCopiableTile(
                            title: 'METHOD',
                            initiallyExpanded: true,
                            subtitle: entry.request.method,
                            builder: null,
                          ),
                          const Divider(height: 0.0),
                          SelectableCopiableTile(
                            title: 'URL',
                            initiallyExpanded: true,
                            subtitle: entry.request.url,
                            builder: null,
                          ),
                          const Divider(height: 0.0),
                          SelectableCopiableTile(
                            title: 'HEADERS',
                            initiallyExpanded: false,
                            subtitle: entry.request.headers.prettyJson,
                            builder: instance.bodyWidgetBuilder,
                          ),
                          if (entry.request.method != 'GET') ...[
                            const Divider(height: 0.0),
                            SelectableCopiableTile(
                              title: 'BODY',
                              initiallyExpanded: false,
                              subtitle: entry.request.body.prettyJson,
                              builder: instance.bodyWidgetBuilder,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Scrollbar(
                      child: ListView(
                        children: [
                          SelectableCopiableTile(
                            title: 'STATUS CODE',
                            initiallyExpanded: true,
                            subtitle: entry.response.statusCode.toString(),
                            builder: null,
                          ),
                          const Divider(height: 0.0),
                          SelectableCopiableTile(
                            title: 'HEADERS',
                            initiallyExpanded: false,
                            subtitle: entry.response.headers.prettyJson,
                            builder: instance.bodyWidgetBuilder,
                          ),
                          const Divider(height: 0.0),
                          SelectableCopiableTile(
                            title: 'BODY',
                            initiallyExpanded: false,
                            subtitle: entry.response.body.prettyJson,
                            builder: instance.bodyWidgetBuilder,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectableCopiableTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool initiallyExpanded;
  final Widget Function(BuildContext context, {required String data})? builder;

  const SelectableCopiableTile({
    required this.title,
    required this.initiallyExpanded,
    required this.subtitle,
    required this.builder,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LazyExpansionTile(
      initiallyExpanded: initiallyExpanded,
      title: SelectableText(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
        onTap: () => _copyToClipboard(context),
      ),
      builder: (context) {
        return builder != null
            ? builder!(context, data: subtitle)
            : Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 20,
                ),
                child: SelectableText(
                  subtitle,
                  onTap: () => _copyToClipboard(context),
                ),
              );
      },
    );
  }

  Future<void> _copyToClipboard(BuildContext context) {
    return subtitle.copyToClipboard(context);
  }
}

class LazyExpansionTile extends StatefulWidget {
  final Widget title;
  final WidgetBuilder builder;
  final bool initiallyExpanded;

  const LazyExpansionTile({
    required this.title,
    required this.builder,
    required this.initiallyExpanded,
  });

  @override
  _LazyExpansionTileState createState() => _LazyExpansionTileState();
}

class _LazyExpansionTileState extends State<LazyExpansionTile> {
  late bool _expanded;

  @override
  void initState() {
    _expanded = widget.initiallyExpanded;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.copy),
          title: widget.title,
          trailing: IconButton(
              onPressed: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              icon: Icon(_expanded ? Icons.minimize : Icons.add)),
        ),
        _expanded ? widget.builder(context) : const SizedBox.shrink(),
      ],
    );
  }
}
