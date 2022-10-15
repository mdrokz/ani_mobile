import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:ani_app/favourites/types.dart' as fav;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:chewie/chewie.dart';
import 'package:localstorage/localstorage.dart';

import 'package:ani_app/favourites/types.dart';
import 'scraper.dart' as scraper;

import 'constants.dart' as constants;

import 'widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ani Mobile',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Ani Mobile'),
    );
  }
}

class Episode extends StatefulWidget {
  const Episode({Key? key, required this.streamLink}) : super(key: key);

  final String streamLink;

  @override
  State<Episode> createState() => EpisodePage();
}

class EpisodePage extends State<Episode> {
  late VlcPlayerController videoPlayerController;
  late ChewieController chewieController;

  @override
  void initState() {
    setState(() {
      videoPlayerController = VlcPlayerController.network(
        widget.streamLink,
        hwAcc: HwAcc.full,
        autoPlay: true,
        autoInitialize: true,
        options: VlcPlayerOptions(),
      );
      chewieController = ChewieController(
        videoPlayerController: videoPlayerController,
        autoPlay: false,
        allowFullScreen: false,
        fullScreenByDefault: false,
        autoInitialize: false,
      );
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.initState();
  }

  void disposeVideoController() async {
    await videoPlayerController.stopRendererScanning();
    await videoPlayerController.dispose();
    chewieController.dispose();
  }

  @override
  void deactivate() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    disposeVideoController();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        Chewie(
          controller: chewieController,
        )
      ],
    ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool isSearching = false;
  List<Map<String, String>> animeList = [];
  List<Map<String, String>> episodes = [];
  LocalStorage storage = LocalStorage(constants.localStorage);
  Map<String, Favourite> favourites = {};

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

    initFavourites();

    _controller.addListener(() {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 1000), () {
        setState(() {
          isSearching = true;
        });
        searchAnime(_controller.value.text);
      });
    });

    super.initState();
  }

  void initFavourites() async {
    final isStorageReady = await storage.ready;

    if (isStorageReady) {
      final jsonStr = storage.getItem("favourites");

      if (jsonStr != null) {
        setState(() {
          favourites = favouriteFromJson(jsonStr);
        });
      }
    }
  }

  void searchAnime(String text) async {
    final searchValue = text.split(" ").join("-");

    if (text != "") {
      final result = await scraper.searchAnime(searchValue);
      setState(() {
        animeList = result;
        isSearching = false;
      });
    } else {
      setState(() {
        isSearching = false;
      });
    }
  }

  void displayEpisodes(String anime) async {
    showDialog(
        context: context,
        builder: (_) {
          return const SizedBox(
            child: Center(child: CircularProgressIndicator()),
            width: 10,
            height: 10,
          );
        });
    final eps = await scraper.getEpisodes(anime);
    setState(() {
      episodes = eps;
    });
    final favourite = favourites[anime];
    setState(() {
      if (favourite != null && favourite.episodes.isEmpty) {
        favourites[anime]?.episodes =
            List.generate(episodes.length, (index) => null);
      }
    });
    Navigator.pop(context);


    // });
    final episodeController = TextEditingController();

    showDialog(
        context: context,
        builder: (BuildContext build) {
          return StatefulBuilder(builder: (context, setState) {

            episodeController.addListener(() {
              // if (_debounce?.isActive ?? false) _debounce?.cancel();
              // _debounce = Timer(const Duration(milliseconds: 500), () {
              final search = episodeController.value.text;

              if (search.isNotEmpty) {
                setState(() {
                  episodes = eps.where((episode) {
                    final name =
                        episode.entries.first.key.split("/").last.split("-").last;
                    return name.contains(search);
                  }).toList();
                });
              } else {
                setState(() {
                  episodes = eps;
                });
              }
            });

            return AlertDialog(
                title: TextField(
                  autocorrect: true,
                  decoration: const InputDecoration(
                    hintText: 'Search for episodes',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(7.0)),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(2.0)),
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  controller: episodeController,
                ),
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
                              final episode = episodes[i].entries.first.key;
                              final cover = episodes[i].entries.first.value;
                              final episodeTitle = episode.split("/").last.split("-").last;
                              final isFavourite =
                                  favourites[anime]?.episodes[i] != null
                                      ? Colors.amberAccent
                                      : Colors.blueGrey;
                              return ListCard(
                                  cover: cover,
                                  title: "Episode $episodeTitle",
                                  onTap: () {
                                    streamEpisode(episode);
                                  },
                                  textStyle: const TextStyle(),
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 0, top: 0, bottom: 0),
                                  children: [
                                    GestureDetector(
                                        onTap: () {
                                          if (isFavourite ==
                                              Colors.amberAccent) {
                                            setState(() {
                                              favourites[anime]
                                                  ?.episodes
                                                  .removeAt(i);
                                              storage.setItem("favourites",
                                                  favouriteToJson(favourites));
                                            });
                                          } else {
                                            setState(() {
                                              favourites[anime]?.episodes[i] =
                                                  fav.Episode(
                                                      title: episode,
                                                      cover: cover);
                                              storage.setItem("favourites",
                                                  favouriteToJson(favourites));
                                            });
                                          }
                                        },
                                        child: Icon(
                                          isFavourite == Colors.amberAccent
                                              ? Icons.star
                                              : Icons.star_border_outlined,
                                          color: isFavourite,
                                        ))
                                  ]);
                            },
                            itemCount: episodes.length,
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
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
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
        title: Text(widget.title),
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
            TextField(
              autocorrect: true,
              decoration: const InputDecoration(
                hintText: 'Search for anime',
                hintStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(7.0)),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(2.0)),
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              controller: _controller,
            ),
            const Divider(),
            isSearching
                ? const SizedBox(
                    child: Center(child: CircularProgressIndicator()),
                    width: 50,
                    height: 50,
                  )
                : Expanded(
                    child: ListView.separated(
                    itemCount: animeList.length,
                    itemBuilder: (_, i) {
                      final anime = animeList[i].entries.first.key;
                      final cover = animeList[i].entries.first.value;
                      final isFavourite = favourites[anime] != null
                          ? Colors.amberAccent
                          : Colors.blueGrey;
                      return ListCard(
                          cover: cover,
                          title: anime,
                          onTap: () {
                            displayEpisodes(anime);
                          },
                          textStyle: const TextStyle(fontSize: 23),
                          padding: const EdgeInsets.only(
                              left: 0, top: 0, right: 40, bottom: 40),
                          children: [
                            GestureDetector(
                                onTap: () {
                                  if (isFavourite == Colors.amberAccent) {
                                    setState(() {
                                      favourites.remove(anime);
                                      storage.setItem("favourites",
                                          favouriteToJson(favourites));
                                    });
                                  } else {
                                    setState(() {
                                      favourites[anime] = Favourite(
                                          title: anime,
                                          cover: cover,
                                          episodes: []);
                                      storage.setItem("favourites",
                                          favouriteToJson(favourites));
                                    });
                                  }
                                },
                                child: Icon(
                                  isFavourite == Colors.amberAccent
                                      ? Icons.star
                                      : Icons.star_border_outlined,
                                  color: isFavourite,
                                ))
                          ]);
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
