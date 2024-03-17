import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String buttonName; 
  final bool enabled;
  final IconData? icon;

  ActionButton({
    super.key,
    required this.buttonName,
    required this.enabled,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    Color buttonColor = enabled ? Color.fromARGB(255, 95, 71, 159) : theme.disabledColor;

    return Container(
      padding: EdgeInsets.all(7.0),
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: 80.0), // Set the minimum width
          child: Container(
            padding: EdgeInsets.all(11.0),
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Wrap( // Use Row to align Icon and Text horizontally
              children: [
                if (icon != null) // Check if icon is not null
                  Icon(
                    icon,
                    color: theme.primaryIconTheme.color
                  ), // Add icon if not null
                SizedBox(width: icon != null ? 8.0 : 0), // Add space between icon and text
                Text(
                  buttonName,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}