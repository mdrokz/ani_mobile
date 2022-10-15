library ani_app.widgets;

import 'package:ani_app/favourites/page.dart';
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
      return ListTile(title: Text(constants.settings[index]),onTap: () {
        switch(constants.settings[index]) {
          case "Favourites": {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) => Favourites(),
              fullscreenDialog: true,
            ));
          } break;
        }
      },);
    },
  ));
}

Widget ListCard({
  required String cover, required String title, required void Function() onTap, required TextStyle textStyle, required EdgeInsetsGeometry padding
,required List<Widget> children}) {
  final split = title.split('/');
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
                  split.length > 1 ? split[2].replaceAll(constants.titleRegex, "") : title,
                  textAlign: TextAlign.center,
                  style: textStyle
                ),
                padding: padding
            ),
          ),
          ...children
          // const Divider()
        ],
      ));
}
