import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutterfire_ui/firestore.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Racing News',
      theme: ThemeData(
        primarySwatch: Colors.blue
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const MyHomePage(title: 'News'),
    );
  }
}

class MyHomePage extends StatefulWidget {

  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final _db = FirebaseFirestore.instance;
  String topic = "news";

  void _changeCategory(String category) {
    if (topic != category) {
      setState(() {
        topic = category;
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Categories',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24
                ),
              ),
            ),
            ListTile(
              onTap: () => _changeCategory('news'),
              title: const Text(
                'All News',
                style: TextStyle(
                  fontSize: 18
                ),
              ),
            ),
            ListTile(
              onTap: () => _changeCategory('f1'),
              title: const Text(
                'Formula 1',
                style: TextStyle(
                  fontSize: 18
                )
              ),
            ),
            ListTile(
              onTap: () => _changeCategory('motoGp'),
              title: const Text(
                'MotoGP',
                style: TextStyle(
                    fontSize: 18
                ),
              ),
            ),
            ListTile(
              onTap: () => _changeCategory('indycar'),
              title: const Text(
                'Indycar',
                style: TextStyle(
                  fontSize: 18
                ),
              ),
            ),
          ],
        )
      ),
      body: FirestoreQueryBuilder(
        builder: (context, snapshot, _) {
          if (snapshot.isFetching) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: snapshot.docs.length,
            padding: const EdgeInsets.all(5),
            itemBuilder: (context, i) {
              if (snapshot.hasMore && i + 1 == snapshot.docs.length) {
                snapshot.fetchMore();
              }
              Map<String, dynamic> news = snapshot.docs[i].data();
              return Card(
                child: ListTile(
                  onTap: () => _createRoute(news['url'], news['title']),
                  leading: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: news['image'] == null
                    ? Image.asset('assets/2180256.png', fit: BoxFit.cover,)
                    : Image.network(news['image'], fit: BoxFit.cover,),
                  ),
                  title: Text(
                    news['title'],
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold
                    ),
                    maxLines: 3,
                  ),
                  subtitle: Text(
                    'Opened: ${news['opened']}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              );
            },
          );
        },
        query: _db.collection(topic).orderBy('addedDate', descending: true),
      )
    );
  }

  _createRoute(String link, String title) {
    _db.collection('news').doc(title).update({'opened': FieldValue.increment(1)});

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => WebViewPage(url: link),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        }
      )
    );
  }
}

class WebViewPage extends StatelessWidget {

  final String url;
  const WebViewPage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: WebView(initialUrl: url,),
    );
  }
}