import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:chewie/chewie.dart';

import 'scraper.dart' as scraper;

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

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

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
    showDialog(context: context, builder: (_) {return const SizedBox(
            child: Center(child: CircularProgressIndicator()),
            width: 10,
            height: 10,
          );});
    var eps = await scraper.getEpisodes(anime);
    Navigator.pop(context);
    showDialog(
        context: context,
        builder: (BuildContext build) {
          return AlertDialog(
              title: const Text("Episodes"),
              content: ListView.separated(
                itemBuilder: (_, i) {
                  final episode = eps[i].entries.first.key;
                  final cover = eps[i].entries.first.value;
                  return Flex(
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
                        child: Text(
                          episode.split('/')[2],
                          // style: const TextStyle(fontSize: 23)
                        ),
                      ),
                      // const Divider()
                    ],
                  );
                },
                itemCount: eps.length,
                padding: const EdgeInsets.all(8),
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                separatorBuilder: (_, i) {
                  return const Divider();
                },
              ));
        });
  }

  void streamEpisode(String episode) async {
    final downloadLink = await scraper.getDpageLink(episode);

    final streamLink = await scraper.decryptLink("https:" + downloadLink);

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
              decoration: const InputDecoration(labelText: "Search for anime"),
              controller: _controller,
            ),
            const Divider(),
            isSearching ? const SizedBox(
              child: Center(child: CircularProgressIndicator()),
              width: 50,
              height: 50,
            ) : Expanded(
                child:  ListView.separated(
              itemCount: animeList.length,
              itemBuilder: (_, i) {
                final anime = animeList[i].entries.first.key;
                final cover = animeList[i].entries.first.value;
                return GestureDetector(
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
                        child: Text(anime.split('/')[2],
                            style: const TextStyle(fontSize: 23)),
                      ),
                      // const Divider()
                    ],
                    // leading: ,
                    // // leading: Image.network(cover, fit: BoxFit.fill,height: 100,width: 50,),
                    // title: Text(anime.split('/')[2]),
                    // onTap: () {
                    //   displayEpisodes(anime);
                    // },
                  ),
                  onTap: () {
                    displayEpisodes(anime);
                  },
                );
              },
              separatorBuilder: (context, _) {
                return const Divider();
              },
              // padding: const EdgeInsets.only(top: 0,right: 0,left: 0,bottom: 5),
              shrinkWrap: true,
            ))
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
