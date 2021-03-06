import 'dart:convert';
import 'dart:io';

import 'package:constants_service/constants_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_service/http_service.dart';
import 'package:layout_service/layout_service.dart';

import 'exception.dart';
import 'header.dart';

typedef HttpMethod = Future<http.Response> Function();

abstract class HttpClientBase {
  Future<Map<String, dynamic>> httpGet({
    Map<String, String> queryParams,
    HttpHeaderType headerType,
  });

  Future<Map<String, dynamic>> httpPost({
    @required Object badRequestModel,
    Map<String, String> queryParams,
    HttpHeaderType headerType,
    Map<String, dynamic> body,
  });
}

class HttpHelper implements HttpClientBase {
  HttpHelper(this.path);

  final http.Client _httpClient = http.Client();
  final String path;

  Future<Map<String, dynamic>> _responseData(
    http.Response response, {
    Object badRequestModel,
  }) async {
    try {
      switch (response.statusCode) {
        // 200
        case HttpStatus.ok:
          return json.decode(utf8.decode(response.bodyBytes))
              as Map<String, dynamic>;
        // 201
        case HttpStatus.created:
        // 204
        case HttpStatus.noContent:
        // 400
        case HttpStatus.badRequest:
          if (badRequestModel == RegisterBadRequest) {
            throw BadRequestException(
              response.request.url.path,
              RegisterBadRequest.fromJson(
                  json.decode(utf8.decode(response.bodyBytes))
                      as Map<String, dynamic>),
            );
          } else if (badRequestModel == LoginBadRequest) {
            throw BadRequestException(
              response.request.url.path,
              LoginBadRequest.fromJson(
                  json.decode(utf8.decode(response.bodyBytes))
                      as Map<String, dynamic>),
            );
          }
          throw NotHandleException(
            response.request.url.path,
            'BadRequest Model not implemented',
            response.statusCode.toString(),
          );
        // 401
        case HttpStatus.unauthorized:
          throw UnauthorisedException(
            response.request.url.path,
            'The Request is Unauthorized',
            response.statusCode.toString(),
          );
        // 403
        case HttpStatus.forbidden:
          throw UnauthorisedException(
            response.request.url.path,
            'Authorization Forbidden',
            response.statusCode.toString(),
          );
        // 404
        case HttpStatus.notFound:
          throw NotFoundException(
            response.request.url.path,
            'This Uri Not Founded',
            response.statusCode.toString(),
          );
        // 500
        case HttpStatus.internalServerError:
          throw ServerException(
            response.request.url.path,
            'Server Error Body',
            utf8.decode(response.bodyBytes),
          );
        // Others
        default:
          throw NotHandleException(
            response.request.url.path,
            'This Status Code Not Handled',
            response.statusCode.toString(),
          );
      }
    } on JsonUnsupportedObjectError catch (e) {
      throw JsonUnsupportedObjectError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> httpGet({
    Map<String, String> queryParams,
    HttpHeaderType headerType = HttpHeaderType.anonymous,
  }) async {
    try {
      return _responseData(
        await _httpClient.get(
          usingLocal
              ? usingSSL
                  ? Uri.https(
                      isMobile ? avdAuthority : authority,
                      '/gallery/api/$path',
                      queryParams,
                    )
                  : Uri.http(
                      isMobile ? avdAuthority : authority,
                      '/gallery/api/$path',
                      queryParams,
                    )
              : usingSSL
                  ? Uri.https(
                      serverUrl,
                      '/gallery/api/$path',
                      queryParams,
                    )
                  : Uri.http(
                      serverUrl,
                      '/gallery/api/$path',
                      queryParams,
                    ),
          headers: HttpHeader.setHeader(headerType),
        ),
      );
    } on SocketException catch (e) {
      throw SocketException(e.url, e.key, e.value);
    } on http.ClientException catch (e) {
      throw http.ClientException(e.message, e.uri);
    }
  }

  @override
  Future<Map<String, dynamic>> httpPost({
    @required Object badRequestModel,
    Map<String, String> queryParams,
    HttpHeaderType headerType,
    Map<String, dynamic> body,
  }) async {
    try {
      return _responseData(
        await _httpClient.post(
          usingLocal
              ? usingSSL
                  ? Uri.https(
                      isMobile ? avdAuthority : authority,
                      '/gallery/api/$path',
                      queryParams,
                    )
                  : Uri.http(
                      isMobile ? avdAuthority : authority,
                      '/gallery/api/$path',
                      queryParams,
                    )
              : usingSSL
                  ? Uri.https(
                      serverUrl,
                      '/gallery/api/$path',
                      queryParams,
                    )
                  : Uri.http(
                      serverUrl,
                      '/gallery/api/$path',
                      queryParams,
                    ),
          headers: HttpHeader.setHeader(headerType ?? HttpHeaderType.anonymous),
          body: json.encode(body),
        ),
        badRequestModel: badRequestModel,
      );
    } on SocketException catch (e) {
      throw SocketException(e.url, e.key, e.value);
    } on JsonUnsupportedObjectError catch (e) {
      throw JsonUnsupportedObjectError(e);
    }
  }
}
