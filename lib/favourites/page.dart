import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

import '../constants.dart' as constants;

import '../main.dart';
import '../widgets.dart';
import 'types.dart' as fav;

import '../scraper.dart' as scraper;

class Favourites extends StatefulWidget {
  const Favourites({Key? key}) : super(key: key);

  @override
  State<Favourites> createState() => FavouritePage();
}

class FavouritePage extends State<Favourites> {
  final storage = LocalStorage(constants.localStorage);
  Map<String,fav.Favourite> favourites = {};


  @override
  void initState() {
    initFavourites();

    super.initState();
  }

  void initFavourites() async {
    final isStorageReady = await storage.ready;

    if(isStorageReady) {
      final jsonStr = storage.getItem("favourites");

      if(jsonStr != null) {
        setState(() {
          favourites = fav.favouriteFromJson(jsonStr);
        });
      }
    }

  }

  void displayEpisodes(fav.Favourite favourite) async {
    showDialog(
        context: context,
        builder: (_) {
          return const SizedBox(
            child: Center(child: CircularProgressIndicator()),
            width: 10,
            height: 10,
          );
        });
    final eps = favourite.episodes.where((element) => element != null).toList();
    Navigator.pop(context);
    showDialog(
        context: context,
        builder: (BuildContext build) {
          return AlertDialog(
              title: const Text("Episodes"),
              content: SingleChildScrollView(
                  child: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      children: [
                        ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.4,
                            ),
                            child: ListView.separated(
                              itemBuilder: (_, i) {
                                final episode = eps[i]?.title ?? "";
                                final cover = eps[i]?.cover ?? "";
                                // final favourite = favourites[anime];
                                return ListCard(
                                    cover: cover,
                                    title: episode,
                                    onTap: () {
                                      streamEpisode(episode);
                                    },
                                    textStyle: const TextStyle(),
                                    padding: const EdgeInsets.only(
                                        left: 10, right: 0, top: 0, bottom: 0),
                                    children: []);
                              },
                              itemCount: eps.length,
                              padding: const EdgeInsets.all(8),
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              separatorBuilder: (_, i) {
                                return const Divider();
                              },
                            ))
                      ],
                      mainAxisSize: MainAxisSize.min,
                    ),
                  )));
        });
  }

  void streamEpisode(String episode) async {
    final downloadLink = await scraper.getDpageLink(episode);

    final data = await scraper.extractKeys("https:" + downloadLink);
    final id = data.keys.first;
    final keyData = data.values.first;
    final streamLink = await scraper.decryptLink(
        keyData.token, id, keyData.decryptKey, keyData.iv);

    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) => Episode(streamLink: streamLink),
      fullscreenDialog: true,
    ));
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Favourites"),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
                child: ListView.separated(
                  itemCount: favourites.keys.length,
                  itemBuilder: (_, i) {
                    final anime = favourites.keys.elementAt(i);
                    final cover = favourites.values.elementAt(i).cover;
                    return ListCard(cover: cover, title: anime, onTap: () {
                      displayEpisodes(favourites.values.elementAt(i));
                    },
                        textStyle: const TextStyle(fontSize: 23),
                        padding: const EdgeInsets.only(
                            left: 0, top: 0, right: 40, bottom: 40),
                        children: []);
                  },
                  separatorBuilder: (context, _) {
                    return const Divider();
                  },
                  shrinkWrap: true,
                ))
          ],
        ),
      ),
      drawer:
      SettingsDrawer(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}