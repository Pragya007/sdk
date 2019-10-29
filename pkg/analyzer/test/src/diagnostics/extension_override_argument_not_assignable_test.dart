// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionOverrideArgumentNotAssignableTest);
    defineReflectiveTests(ExtensionOverrideArgumentNotAssignableWithNNBDTest);
  });
}

@reflectiveTest
class ExtensionOverrideArgumentNotAssignableTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  test_subtype() async {
    await assertNoErrorsInCode('''
class A {}
class B extends A {}
extension E on A {
  void m() {}
}
void f(B b) {
  E(b).m();
}
''');
  }

  test_supertype() async {
    // This will be an error under NNBD.
    await assertNoErrorsInCode('''
class A {}
class B extends A {}
extension E on B {
  void m() {}
}
void f(A a) {
  E(a).m();
}
''');
  }

  test_unrelated() async {
    await assertErrorsInCode('''
class A {}
class B {}
extension E on A {
  void m() {}
}
void f(B b) {
  E(b).m();
}
''', [
      error(CompileTimeErrorCode.EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE, 75,
          1),
    ]);
  }

  test_void() async {
    await assertErrorsInCode('''
class C {
  String name = "My name is C";
}

extension ExtendedC on C {
  String checkme() => this.name;
}

void getC() => new C();

main() {
  ExtendedC(getC()).checkme();
}
''', [
      error(CompileTimeErrorCode.EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE,
          154, 6),
    ]);
  }
}

@reflectiveTest
class ExtensionOverrideArgumentNotAssignableWithNNBDTest
    extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0',
        additionalFeatures: [Feature.extension_methods, Feature.non_nullable]);

  test_override_onNonNullable() async {
    await assertErrorsInCode(r'''
extension E on String {
  void m() {}
}
f() {
  E(null).m();
}
''', [
      error(CompileTimeErrorCode.EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE, 50,
          4),
    ]);
  }

  test_override_onNullable() async {
    await assertNoErrorsInCode(r'''
extension E on String? {
  void m() {}
}
f() {
  E(null).m();
}
''');
  }
}
