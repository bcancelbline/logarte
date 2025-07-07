import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logarte/logarte.dart';

extension LogarteNetworkEntryXs on NetworkLogarteEntry {
  String get asReadableDuration {
    if (request.sentAt == null || response.receivedAt == null) {
      return 'N/A ms';
    }

    return '${response.receivedAt!.difference(request.sentAt!).inMilliseconds} ms';
  }

  String curlCommand() {
    final components = <String>['curl'];

    String method = request.method.toUpperCase();
    if (method != 'GET') {
      components.add("-X $method \\");
    }

    Map<String, dynamic>? headers = request.headers;
    if (headers != null) {
      headers.forEach((key, value) {
        components.add("-H '${_escape(key)}: ${_escape(value.toString())}' \\");
      });
    }

    Object? body = request.body;
    if (body != null) {
      /// FormData can't be JSON-serialized, so keep only their fields attributes
      /// ! this might break but we deal with this later if needed
      if (body is FormData) {
        body = Map.fromEntries(body.fields);
      }

      /// encode it
      final bodyString = body is String ? body : jsonEncode(body);
      components.add("-d '${_escape(bodyString)}' \\");
    }

    components.add("'${request.url}'");

    return components.join('\n  ');
  }

  String _escape(String input) {
    return input.replaceAll("'", r"'\''");
  }
}
