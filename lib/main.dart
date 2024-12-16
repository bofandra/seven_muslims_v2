import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

int? selectedIndex;
final myTags = TextEditingController();
final myController = TextEditingController();

List<String> tags = [
  "Law of inheritance in Islam",
  "Tunjukilah jalan yang lurus",
  "Why is men created?"
];
List<String> questions = [];
//var questions = [];
var answers = [];
var types = [];

var histories = [
  {
    "source": "remote",
    "type": "moslem-bot-be",
    "question": "bla bla",
    "answer": []
  }
];

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seven Muslims',
      home: MyCustomForm(),
      scaffoldMessengerKey: scaffoldKey,
    );
  }
}

final scaffoldKey = GlobalKey<ScaffoldMessengerState>();

class ProgressIndicatorExample extends StatefulWidget {
  const ProgressIndicatorExample({super.key});

  @override
  State<ProgressIndicatorExample> createState() =>
      _ProgressIndicatorExampleState();
}

showExamples(TextEditingController myController) {
  List<ActionChip> examples = [];
  for (var x in tags)
    examples.add(ActionChip(
      label: Text(x),
      onPressed: () {
        myController.text = x;
      },
    ));
  return examples;
}

class _ProgressIndicatorExampleState extends State<ProgressIndicatorExample>
    with TickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(
      /// [AnimationController]s can be created with `vsync: this` because of
      /// [TickerProviderStateMixin].
      vsync: this,
      duration: const Duration(seconds: 30),
    )..addListener(() {
        setState(() {});
      });
    controller.repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text(
              'Please wait, while we process the best query result for you 🙏 ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            CircularProgressIndicator(
              value: controller.value,
              semanticsLabel: 'Circular progress indicator',
            ),
          ],
        ),
      ),
    );
  }
}

// Define a custom Form widget.
class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  State<MyCustomForm> createState() => _MyCustomFormState();
}

Future<List> fetchQuranFinder(String feature, String query) async {
  if (query.length < 3) {
    return [
      ['Query is empty']
    ];
  }
  for (var v = 0; v < histories.length; v++) {
    if (histories[v]["question"] == query && histories[v]["type"] == feature) {
      return histories[v]["answer"];
    }
  }

  const int timeout = 30;
  var get_url = 'https://bofandra-' + feature + '.hf.space/call/predict';
  print(get_url);

  Map get_data = {
    'data': [query]
  };

  if (feature == "moslem-bot-be") {
    get_data = {
      'data': [query, 100, 0.7, 0.95]
    };
  }
  //encode Map to JSON
  var body = json.encode(get_data);

  var response = await http.post(Uri.parse(get_url),
      headers: {
        "Content-Type": "application/json",
        'charset': 'UTF-8',
        'Authorization': 'Bearer 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'
      },
      body: body);
  print(response.body);
  String event_id = json.decode(response.body)["event_id"];

  print(event_id);
  final url = Uri.parse(
      'https://bofandra-' + feature + '.hf.space/call/predict/' + event_id);
  final client = http.Client();
  var data = [];
  print("cek");
  print(url);
  try {
    final request = http.Request('GET', url);
    request.headers['Authorization'] =
        "Bearer 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";
    final response =
        await client.send(request).timeout(const Duration(seconds: timeout));
    // Read and print the chunks from the response stream
    await for (var chunk in response.stream.transform(utf8.decoder)) {
      // Process each chunk as it is received
      print(chunk);
      if (chunk.contains("data")) {
        print("here");
        chunk = chunk.replaceAll("event: heartbeat", "");
        chunk = chunk.replaceAll("event: complete", "");
        chunk = chunk.replaceAll("event: error", "");
        chunk = chunk.replaceAll("event: generating", "");
        chunk = chunk.replaceAll("data: ", "");
        chunk = chunk.replaceAll(", [NaN]", "");
        chunk = chunk.replaceAll("[NaN], ", "");
        chunk = chunk.replaceAll("[NaN]", "");
        //chunk = chunk.replaceAll("null", "");

        print("chunk length: " + (chunk.length).toString());
        /*if (chunk.length < 7) {
          client.close();
        }*/
        //debugPrint(chunk, wrapWidth: 1000);

        if (feature == "moslem-bot-be" && chunk.length > 7) {
          chunk = chunk.replaceAll("null", "");
          //debugPrint(chunk, wrapWidth: 1000);
          print("=====moslem-bot-be data======");
          print(chunk);
          var str = chunk;
          var parts = str.split('["');
          var content = parts[parts.length - 1].trim();
          print(content);
          print("cek1");
          //var list = [chunk];
          List<dynamic> list = json.decode('["' + content);
          //list.add(chunk);
          print(list.length);
          print("cek2");
          if (list.length > 0) {
            print("cek3");
            print(list);
            print(list.length.toString());
            data = list;
          }
          print("cek4");
          print(data);
        } else {
          var str = chunk;
          var parts = str.split('[');
          var prefix = parts[0].trim();
          var content = parts.sublist(1).join('[').trim();
          print("content:" + content);
          List<dynamic> list = json.decode("[" + content);
          data = list[0]['data'];
          print(data);
        }

        //debugPrint(data, wrapWidth: 1000);
      }
    }
  } catch (e) {
    print("cok");
    print(e);
    return [
      ['Failed to load data']
    ];
    //throw Exception('Failed to load quran-finder');
  } finally {
    print("cik");
    if (feature == "moslem-bot-be") {
      print("ahuhu");
      print("data length=" + (data.length).toString());
      //data = [data[data.length - 1]];
    }
    print(data);
    client.close();
    if (data.length > 0) {
      var temp = {"question": query, "type": feature, "answer": data};
      /*questions.add(query);
      answers.add(data);
      types.add(feature);*/
      histories.add(temp);
      return data;
    } else {
      return [
        ['Failed to load data']
      ];
    }
  }
}

// Define a corresponding State class.
// This class holds the data related to the Form.
class _MyCustomFormState extends State<MyCustomForm> {
  // Create a text controller and use it to retrieve the current value
  // of the TextField.
  bool favorite = false;
  late Future<List> futureQuranFinder;
  late Future<List> futureHadithsFinder;
  late Future<List> futureBotFinder;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  void askmoslembot() {
    futureQuranFinder = fetchQuranFinder("moslem-bot-be", myController.text);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Retrieve the text the that user has entered by using the
          // TextEditingController.
          //content: Text(myController.text),
          title: Text("Moslem Bot"),
          content: FutureBuilder<List>(
            future: futureQuranFinder,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                print(snapshot.data!);
                print(snapshot.data![0].length);
                if (snapshot.data![0].length > 5) {
                  print("here");
                  return ListView(children: [
                    RichText(
                      text: TextSpan(
                          text: snapshot.data![0] +
                              "\n\n-------------------\nGet more results in https://huggingface.co/spaces/Bofandra/moslem-bot",
                          style: TextStyle(color: Colors.lightBlue.shade900),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              launchUrl(Uri.parse(
                                  "https://huggingface.co/spaces/Bofandra/moslem-bot"));
                            }),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    TextButton(
                        child: const Text(
                          'Copy to Clipboard',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        onPressed: () async {
                          await Clipboard.setData(
                                  ClipboardData(text: snapshot.data![0]))
                              .then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Text copied to clipboard")));
                          });
                        }),
                  ]);
                } else {
                  print("there");
                  return Text(
                      //"I'm sorry for unable to fulfill your query right now..");
                      snapshot.data![0][0]);
                }
                //return Text(verse + " (" + note + ")");
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }

              // By default, show a loading spinner.
              return const ProgressIndicatorExample();
            },
          ),
        );
      },
    );
  }

  void findinquran() {
    setState(() {
      if (!tags.contains(myController.text) && myController.text.isNotEmpty) {
        tags.add(myController.text);
      }
      selectedIndex = tags.length - 1;
    });
    futureQuranFinder = fetchQuranFinder("quran-finder-be", myController.text);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Retrieve the text the that user has entered by using the
          // TextEditingController.
          //content: Text(myController.text),
          title: Text("Quran Finder"),
          content: FutureBuilder<List>(
            future: futureQuranFinder,
            builder: (context, snapshot) {
              print("cekpoin1");
              if (snapshot.hasData) {
                print("cekpoin2");
                print(snapshot.data!);
                if (snapshot.data!.length > 1) {
                  var clipboard = "";
                  final text = [];
                  for (var teks in snapshot.data!) {
                    var str = teks[0];
                    var start = '">';
                    var end = "</a>";
                    var startIndex = str.indexOf(start);
                    var endIndexVerse =
                        str.indexOf(end, startIndex + start.length);
                    var verse =
                        str.substring(startIndex + start.length, endIndexVerse);

                    start = 'href="';
                    end = '">';
                    startIndex = str.indexOf(start);
                    var endIndex = str.indexOf(end, startIndex + start.length);
                    var link =
                        str.substring(startIndex + start.length, endIndex);

                    start = '(';
                    end = ')';
                    startIndex = str.indexOf(start, endIndexVerse);
                    endIndex = str.indexOf(end, startIndex + start.length);
                    var note =
                        str.substring(startIndex + start.length, endIndex);

                    text.add(
                        {'verse': verse + " (" + note + ")", 'link': link});
                    clipboard = clipboard +
                        "\n\n" +
                        verse +
                        " (" +
                        note +
                        ")" +
                        "\n" +
                        link;
                  }

                  text.add({
                    'verse':
                        "Get more results in https://huggingface.co/spaces/Bofandra/quran-finder",
                    'link':
                        "https://huggingface.co/spaces/Bofandra/quran-finder"
                  });

                  //return Text(verse + " (" + note + ")");
                  return ListView(children: [
                    for (var pair in text)
                      RichText(
                        text: TextSpan(
                            text: "\n" +
                                (text.indexOf(pair) + 1).toString() +
                                ") ",
                            children: [
                              TextSpan(
                                style: TextStyle(
                                  color: Colors.lightBlue.shade900,
                                ),
                                text: pair['verse'],
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(Uri.parse(pair['link']));
                                  },
                              )
                            ]),
                      ),
                    SizedBox(
                      height: 10,
                    ),
                    TextButton(
                        child: const Text(
                          'Copy to Clipboard',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        onPressed: () async {
                          await Clipboard.setData(
                                  ClipboardData(text: clipboard))
                              .then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Text copied to clipboard")));
                          });
                        }),
                  ]);
                } else {
                  return Text(
                      //"I'm sorry for unable to fulfill your query right now..");
                      snapshot.data![0][0]);
                }
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }

              // By default, show a loading spinner.
              return const ProgressIndicatorExample();
            },
          ),
        );
      },
    );
  }

  void findhadiths() {
    futureQuranFinder =
        fetchQuranFinder("hadiths-finder-be", myController.text);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Retrieve the text the that user has entered by using the
          // TextEditingController.
          //content: Text(myController.text),
          title: Text("Hadiths Finder"),
          content: FutureBuilder<List>(
            future: futureQuranFinder,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                print(snapshot.data!);
                if (snapshot.data!.length > 1) {
                  final text = [];
                  var clipboard = "";
                  for (var teks in snapshot.data!) {
                    var str = teks[0];
                    var start = '">';
                    var end = "</a>";
                    var startIndex = str.indexOf(start);
                    var endIndexVerse =
                        str.indexOf(end, startIndex + start.length);
                    var verse =
                        str.substring(startIndex + start.length, endIndexVerse);

                    start = 'href="';
                    end = '">';
                    startIndex = str.indexOf(start);
                    var endIndex = str.indexOf(end, startIndex + start.length);
                    var link =
                        str.substring(startIndex + start.length, endIndex);

                    start = '(';
                    end = ')';
                    startIndex = str.indexOf(start, endIndexVerse);
                    endIndex = str.indexOf(end, startIndex + start.length);
                    var note =
                        str.substring(startIndex + start.length, endIndex);

                    text.add(
                        {'verse': verse + " (" + note + ")", 'link': link});

                    clipboard = clipboard +
                        "\n\n" +
                        verse +
                        " (" +
                        note +
                        ")" +
                        "\n" +
                        link;
                  }

                  text.add({
                    'verse':
                        "Get more results in https://huggingface.co/spaces/Bofandra/hadiths-finder",
                    'link':
                        "https://huggingface.co/spaces/Bofandra/hadiths-finder"
                  });

                  //return Text(verse + " (" + note + ")");
                  return ListView(children: [
                    for (var pair in text)
                      RichText(
                        text: TextSpan(
                            text: "\n" +
                                (text.indexOf(pair) + 1).toString() +
                                ") ",
                            children: [
                              TextSpan(
                                style: TextStyle(
                                  color: Colors.lightBlue.shade900,
                                ),
                                text: pair['verse'],
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(Uri.parse(pair['link']));
                                  },
                              )
                            ]),
                      ),
                    SizedBox(
                      height: 10,
                    ),
                    TextButton(
                        child: const Text(
                          'Copy to Clipboard',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        onPressed: () async {
                          await Clipboard.setData(
                                  ClipboardData(text: clipboard))
                              .then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Text copied to clipboard")));
                          });
                        }),
                  ]);
                } else {
                  return Text(
                      //"I'm sorry for unable to fulfill your query right now..");
                      snapshot.data![0][0]);
                }
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }

              // By default, show a loading spinner.
              return const ProgressIndicatorExample();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final _key = GlobalKey<ExpandableFabState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seven Muslims'),
      ),
      body: Container(
          margin: const EdgeInsets.all(16),
          child: Column(children: [
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.search, size: 19.0),
                        Text(
                          'Quran',
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        )
                      ],
                    ),
                    onPressed: findinquran,
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.search, size: 19.0),
                        Text(
                          'Hadiths',
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        )
                      ],
                    ),
                    onPressed: findhadiths,
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.chat_bubble_outline_rounded, size: 19.0),
                        Text(
                          'Ask Bot',
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        )
                      ],
                    ),
                    onPressed: askmoslembot,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            TextField(
              keyboardType: TextInputType.multiline,
              maxLines: null,
              controller: myController,
              decoration: InputDecoration(
                labelText: 'Type your query..',
                hintText: 'Multiple line is allowed',
                filled: true,
              ),
            ),
            const SizedBox(height: 10),
            Text("Examples:"),
            const SizedBox(height: 5),
            Column(children: <Widget>[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 5.0,
                children: List<Widget>.generate(
                  tags.length,
                  (int index) {
                    return InputChip(
                      label: Text(tags[index]),
                      selected: selectedIndex == index,
                      onSelected: (bool selected) {
                        myController.text = tags[index];
                        setState(() {
                          if (selectedIndex == index) {
                            selectedIndex = null;
                          } else {
                            selectedIndex = index;
                          }
                        });
                      },
                      onDeleted: () {
                        setState(() {
                          tags.removeAt(index);
                        });
                      },
                    );
                  },
                ).toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        tags = [
                          "Law of inheritance in Islam",
                          "Tunjukilah jalan yang lurus",
                          "Why is men created?"
                        ];
                      });
                    },
                    child: Text('default'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        tags = [
                          "Law of inheritance in Islam",
                          "Tunjukilah jalan yang lurus",
                          "Why is men created?"
                        ];
                      });
                    },
                    child: Text('local'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        tags = [
                          "Law of inheritance in Islam",
                          "Tunjukilah jalan yang lurus",
                          "Why is men created?"
                        ];
                      });
                    },
                    child: Text('others'),
                  )
                ],
              )
            ]),
          ])),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        key: _key,
        // duration: const Duration(milliseconds: 500),
        distance: 70.0,
        type: ExpandableFabType.up,
        // pos: ExpandableFabPos.left,
        // childrenOffset: const Offset(0, 20),
        // childrenAnimation: ExpandableFabAnimation.none,
        // fanAngle: 40,
        overlayStyle: ExpandableFabOverlayStyle(
          color: Colors.black.withOpacity(0.5),
          blur: 5,
        ),
        children: [
          FloatingActionButton.extended(
            // When the user presses the button, show an alert dialog containing
            // the text that the user has entered into the text field.
            onPressed: () {
              setState(() {
                tags = [
                  "Law of inheritance in Islam",
                  "Tunjukilah jalan yang lurus",
                  "Why is men created?"
                ];
              });
            },
            label: const Text('Default Examples!'),
          ),
          FloatingActionButton.extended(
            // When the user presses the button, show an alert dialog containing
            // the text that the user has entered into the text field.
            onPressed: () {
              setState(() {
                List<String> localQuestions = [];
                for (int f = 0; f < histories.length; f++) {
                  localQuestions.add(histories[f]["question"].toString());
                }
                tags = localQuestions;
                //tags = questions;
              });
            },
            label: const Text('Local Histories'),
          ),
          FloatingActionButton.extended(
            // When the user presses the button, show an alert dialog containing
            // the text that the user has entered into the text field.
            onPressed: () {
              setState(() {
                tags = [
                  "Law of inheritance in Islam",
                  "Tunjukilah jalan yang lurus",
                  "Why is men created?"
                ];
              });
            },
            label: const Text("Everyone Histories"),
          ),
        ],
      ),
    );
  }
}
