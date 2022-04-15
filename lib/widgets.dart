library ani_app.widgets;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:ani_app/constants.dart' as constants;

Widget SettingsDrawer() {
  return Drawer(
      child: ListView.separated(
    padding: EdgeInsets.zero,
    separatorBuilder: (_, i) {
      return const Divider();
    },
    itemCount: constants.settings.length,
    itemBuilder: (BuildContext context, int index) {
      if (index == 0) {
        return const DrawerHeader(
          child: Text('Settings'),
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
        );
      }
      return ListTile(title: Text(constants.settings[index]));
    },
  ));
}

Widget ListCard(
    String cover, String title, void Function() onTap, TextStyle textStyle,EdgeInsetsGeometry padding) {
  return GestureDetector(
      onTap: onTap,
      child: Flex(
        direction: Axis.horizontal,
        children: [
          ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 100,
                minHeight: 100,
                maxWidth: 100,
                maxHeight: 200,
              ),
              child: Image.network(
                cover,
                fit: BoxFit.cover,
              )),
          Expanded(
            child: Container(
                child: Text(
                  title.split('/')[2],
                  textAlign: TextAlign.center,
                  style: textStyle
                ),
                padding: padding
            ),
          ),
          const Icon(Icons.star_border_outlined,color: Colors.blueGrey,)
          // const Divider()
        ],
      ));
}
