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
      if(index == 0) {
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
