import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

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
      home: GetGroupNameScreen(),
    );
  }
}

class GetGroupNameScreen extends StatefulWidget {
  const GetGroupNameScreen({super.key});

  @override
  State<GetGroupNameScreen> createState() => _GetGroupNameScreenState();
}

class _GetGroupNameScreenState extends State<GetGroupNameScreen> {
  late final TextEditingController groupNameController;

  @override
  void initState() {
    groupNameController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Name'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: groupNameController,
              decoration: const InputDecoration(labelText: 'Room Name'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (groupNameController.text.trim().isEmpty == true) {
                  return;
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (cntxt) {
                        return HomeScreen(
                          groupName: groupNameController.text.trim(),
                        );
                      },
                    ),
                  );
                }
              },
              child: const Text('Connect The Room'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String groupName;
  const HomeScreen({super.key, required this.groupName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebSocketChannel channel;
  final TextEditingController messageController = TextEditingController();
  late final ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();
    super.initState();
    connectToWsServer(widget.groupName);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {});
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
        title: Text('Room name: "${widget.groupName}"'),
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
                          log(data.toString());
                          return Card(
                            elevation: 7,
                            child: ListTile(
                              title: Text(data[index]['userMessage']),
                              subtitle: Text(data[index]['username']),
                            ),
                          );
                        },
                      );
                    } else if (snapshot.hasError) {
                      log(snapshot.error.toString());
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

  void connectToWsServer(String groupName) {
    try {
      channel = IOWebSocketChannel.connect(
        Uri.parse('ws://10.0.2.2:8000/chat/$groupName/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNjkzNjQzNjI2LCJpYXQiOjE2OTM2NDMzMjYsImp0aSI6IjM1ZjMxZDZmMTc3YzQ2MGJhYTBmMDk0NTEzMmYxMjNmIiwidXNlcl9pZCI6MX0.VtZz31xGYx1fNqRmEUW0tAs8eTCvsO1h8kvRHbgs4gA'
        },
      );
    } catch (error) {
      log(error.toString());
    }
  }

  void sendDataToWsServer(String message) {
    channel.sink.add(jsonEncode(message));
  }

  void closeConnectToWsServer() {
    channel.sink.close();
  }
}
