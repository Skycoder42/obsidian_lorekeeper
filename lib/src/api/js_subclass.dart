import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('Reflect.construct')
external JSObject _construct(
  JSFunction target,
  JSArray<JSAny?> args,
  JSFunction newTarget,
);

@JS('Object.defineProperty')
external void _defineProperty(
  JSObject object,
  String property,
  JSObject descriptor,
);

/// Constructs an instance of the JS class [base] that behaves like an instance
/// of a JS subclass of it.
///
/// [wrap] receives `base.prototype` and must return the object that holds the
/// subclass members, typically `createJSInteropWrapper(this, prototype)`. That
/// object is inserted into the prototype chain between the new instance and
/// `base.prototype`, so base class methods dispatch to its members. The base
/// constructor runs as usual with [args].
///
/// Exported members must not use any name the base constructor assigns as an
/// instance field, as the constructor would then write to the exported
/// property instead of creating its own field.
T constructJSSubclass<T extends JSObject>(
  JSFunction base,
  List<JSAny?> args,
  JSObject Function(JSObject prototype) wrap,
) {
  // Reflect.construct takes the prototype of the new instance from newTarget.
  // A bound copy of base is a valid constructor that needs no JS source.
  final newTarget = base.callMethod<JSFunction>('bind'.toJS);
  // Not an assignment: For ES6 classes, newTarget inherits a read-only
  // prototype property from the parent class, so assigning silently fails.
  _defineProperty(
    newTarget,
    'prototype',
    JSObject()..['value'] = wrap(base['prototype']! as JSObject),
  );
  return _construct(base, args.toJS, newTarget) as T;
}
