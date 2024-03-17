import 'package:flutter/material.dart';

class RippleButton extends StatelessWidget {
  final Function()? onPressed;
  final Widget child;
  final Color splashColor;

  const RippleButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.splashColor = Colors.transparent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        splashColor: splashColor,
        child: child,
      ),
    );
  }
}
