// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:dartdoc/src/dartdoc_options.dart';
import 'package:dartdoc/src/model/model.dart';
import 'package:dartdoc/src/package_config_provider.dart';
import 'package:dartdoc/src/package_meta.dart';
import 'package:test/test.dart';

import 'src/utils.dart' as utils;

void main() {
  MemoryResourceProvider resourceProvider;
  MockSdk mockSdk;
  Folder sdkFolder;

  PackageMetaProvider packageMetaProvider;
  FakePackageConfigProvider packageConfigProvider;

  setUp(() async {
    resourceProvider = MemoryResourceProvider();
    mockSdk = MockSdk(resourceProvider: resourceProvider);
    sdkFolder = utils.writeMockSdkFiles(mockSdk);

    packageMetaProvider = PackageMetaProvider(
      PubPackageMeta.fromElement,
      PubPackageMeta.fromFilename,
      PubPackageMeta.fromDir,
      resourceProvider,
      sdkFolder,
      defaultSdk: mockSdk,
    );
    var optionSet = await DartdocOptionSet.fromOptionGenerators(
        'dartdoc', [createDartdocOptions], packageMetaProvider);
    optionSet.parseArguments([]);
    packageConfigProvider = FakePackageConfigProvider();
    // To build the package graph, we always ask package_config for a
    // [PackageConfig] for the SDK directory. Put a dummy entry in.
    packageConfigProvider.addPackageToConfigFor(
        sdkFolder.path, 'analyzer', Uri.file('/sdk/pkg/analyzer/'));
  });

  test('libraries in SDK package have appropriate data', () async {
    var packageGraph = await utils.bootBasicPackage(
        sdkFolder.path, packageMetaProvider, packageConfigProvider,
        additionalArguments: [
          '--input',
          packageMetaProvider.defaultSdkDir.path,
        ]);

    var localPackages = packageGraph.localPackages;
    expect(localPackages, hasLength(1));
    var sdkPackage = localPackages.single;
    expect(sdkPackage.name, equals('Dart'));

    var dartAsyncLib =
        sdkPackage.libraries.firstWhere((l) => l.name == 'dart:async');
    expect(dartAsyncLib.name, 'dart:async');
    expect(dartAsyncLib.dirName, 'dart-async');
    expect(dartAsyncLib.href,
        '${HTMLBASE_PLACEHOLDER}dart-async/dart-async-library.html');
  });
}
