import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// A widget that makes it easy to execute a [Stream] from a StatelessWidget.
class Streamistic<T> extends StatefulWidget {
  /// Function that returns the [Stream] to execute. Not the [Stream] itself.
  final Stream<T> streamBuilder; // was AsyncValueGetter

  /// Widget to display before the [Stream] starts executing.
  /// Call [VoidCallback] to start executing the [Stream].
  /// If not null, [autoStart] should be false.
  final Widget Function(BuildContext, VoidCallback) initialBuilder;

  /// Widget to display while the [Stream] is executing.
  /// If null, a [CircularProgressIndicator] will be displayed.
  final WidgetBuilder busyBuilder;
  
  /// Widget to display when the [Stream] has completed with an error.
  /// If null, [initialBuilder] will be displayed again.
  /// The [Object] is the [Error] or [Exception] returned by the [Stream].
  /// Call [VoidCallback] to start executing the [Stream] again.
  final Widget Function(BuildContext, Object, VoidCallback) errorBuilder;

  /// Widget to display when the [Stream] has completed successfully.
  /// If null, [initialBuilder] will be displayed again.
  final Widget Function(BuildContext, T) dataBuilder;

  /// Callback to invoke when the [Stream] has completed successfully.
  /// Will only be invoked once per [Stream] execution.
  final ValueChanged<T> onData;

  /// Callback to invoke when the [Stream] has completed with an error.
  /// Will only be invoked once per [Stream] execution.
  /// Call [VoidCallback] to start executing the [Stream] again.
  final Function(Object, VoidCallback) onError;

  const Streamistic({
    Key key,
    @required this.streamBuilder,
    this.initialBuilder,
    this.busyBuilder,
    this.errorBuilder,
    this.dataBuilder,
    this.onData,
    this.onError
  })  : assert(streamBuilder != null),
        super(key: key);

  @override
  _StreamisticState<T> createState() => _StreamisticState<T>();
}

class _StreamisticState<T> extends State<Streamistic<T>> {
  Stream<T> _stream;

  @override
  void initState() {
    super.initState();
    _execute();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: _stream,
      builder: (_context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return widget.initialBuilder(context, _execute);
          case ConnectionState.waiting:
          case ConnectionState.active:
            return _handleBusy(_context);
          case ConnectionState.done:
            return _handleSnapshot(_context, snapshot);
          default:
            return _defaultWidget();
        }
      },
    );
  }

  Widget _handleSnapshot(BuildContext context, AsyncSnapshot<T> snapshot) {
    if (snapshot.hasError) {
      return _handleError(context, snapshot.error);
    }
    return _handleData(context, snapshot.data);
  }

  Widget _handleError(BuildContext context, Object error) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder(context, error, _execute);
    }

    if (widget.initialBuilder != null) {
      return widget.initialBuilder(context, _execute);
    }

    return _defaultWidget();
  }

  Widget _handleData(BuildContext context, T data) {
    if (widget.dataBuilder != null) {
      return widget.dataBuilder(context, data);
    }

    if (widget.initialBuilder != null) {
      return widget.initialBuilder(context, _execute);
    }

    return _defaultWidget();

  }

  Widget _handleBusy(BuildContext context) {
    if (widget.busyBuilder == null) {
      return _defaultBusyWidget();
    }
    return widget.busyBuilder(context);
  }

  void _execute() {
    setState(() {
      _stream = widget.streamBuilder();
      _stream.then(_onData).catchError(_onError);
    });
  }

  void _onData(T data) async {
    if (widget.onData != null && _isActive()) {
      widget.onData(data);
    }
  }

  void _onError(Object e) async {
    if (widget.onError != null && _isActive()) {
      widget.onError(e, _execute);
    }
  }

  bool _isActive() => mounted && (ModalRoute.of(context)?.isActive ?? true);

  Widget _defaultBusyWidget() => const Center(child: CircularProgressIndicator());

  Widget _defaultWidget() => const SizedBox.shrink();
}
