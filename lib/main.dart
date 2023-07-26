import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebSocketChannel channel;
  late final TextEditingController messageController;
  final List<String> messages = [];
  late int count;
  late final ScrollController _scrollController;

  @override
  void initState() {
    messageController = TextEditingController();
    _scrollController = ScrollController();
    count = 0;
    connectToWsServer();
    super.initState();
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    closeConnectToWsServer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat App'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: StreamBuilder(
                  stream: channel.stream,
                  builder: (cntxt, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasData) {
                      var data = jsonDecode(snapshot.data);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollController
                            .jumpTo(_scrollController.position.maxScrollExtent);
                      });
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        itemCount: data.length,
                        itemBuilder: (cntxt, index) {
                          return Card(
                            elevation: 7,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(data[index]['userMessage']),
                            ),
                          );
                        },
                      );
                    } else if (snapshot.hasError) {
                      print(snapshot.error.toString());
                      return Text(snapshot.error.toString());
                    }

                    return const Text('Other error..');
                  },
                ),
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Enter your message.',
                    suffixIcon: IconButton(
                      onPressed: () {
                        if (messageController.text.trim().isNotEmpty) {
                          sendDataToWsServer(messageController.text.trim());
                          messageController.clear();
                        }
                      },
                      icon: const Icon(Icons.send),
                    ),
                  ),
                  maxLines: 2,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void connectToWsServer() {
    try {
      channel =
          WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:8000/chat/abc/'));
    } catch (error) {
      print(error);
    }
  }

  void sendDataToWsServer(String message) {
    channel.sink.add(jsonEncode(message));
  }

  void closeConnectToWsServer() {
    channel.sink.close();
  }
}
