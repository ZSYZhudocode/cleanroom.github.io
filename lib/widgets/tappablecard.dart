import 'package:flutter/material.dart';
import '../model/resource.dart';
import 'package:flutter/cupertino.dart';

class TappableCard extends StatelessWidget {
  final Function(Resource)? onTap;
  final Widget? child;
  final Resource resource;
  final bool isSelected;

  TappableCard({
    Key? key, 
    this.onTap, 
    required this.resource, 
    this.child, 
    required this.isSelected
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    TextStyle textStyle;
    ThemeData theme = Theme.of(context);
    double borderWidth = isSelected ? 3.0 : 0.5;
    Widget icon;
    
    if (resource is Directory) {
      cardColor = theme.primaryColor;
      IconData dirIcon;
      if ((resource as Directory).contents.isEmpty) {
        dirIcon = CupertinoIcons.collections;
      } else {
        dirIcon = CupertinoIcons.collections_solid;
      }
      icon = Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: Icon(
          dirIcon,
          color: theme.primaryIconTheme.color
        ),
      );
      textStyle = TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600, 
        color: theme.colorScheme.onPrimary
      );
    } else {
      cardColor = theme.unselectedWidgetColor;
      icon = Icon(
        CupertinoIcons.doc,
        color: theme.primaryColorLight
      );
      textStyle = TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400, 
        color: theme.colorScheme.onPrimary
      );
    }

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!(resource);
        }
      },
      child: Card(
        shape: RoundedRectangleBorder( // Set the shape to RoundedRectangleBorder
          borderRadius: BorderRadius.circular(15.0), // Adjust border radius as needed
          side: BorderSide(color: theme.primaryColorLight, width: borderWidth), // Set the border side properties
        ),
        color: cardColor,
        elevation: 7, // Card elevation (shadow)
        margin: EdgeInsets.all(8), // Card margin
        child: Wrap(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: icon,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 0.0, top: 11.0, right: 12.0, bottom: 12.0),
                  child: Text(
                    resource.name,
                    style: textStyle,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(2.0),
              child: child,
            )
          ],
        ),
      ),
    );
  }
}