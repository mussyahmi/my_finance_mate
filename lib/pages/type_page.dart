import 'package:flutter/material.dart';

import 'category_list_page.dart';
import 'savings_page.dart';

class TypePage extends StatefulWidget {
  final String cycleId;

  const TypePage({Key? key, required this.cycleId}) : super(key: key);

  @override
  TypePageState createState() => TypePageState();
}

class TypePageState extends State<TypePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Type'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('Spent'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CategoryListPage(
                                cycleId: widget.cycleId,
                                type: 'spent',
                              )),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  title: const Text('Received'),
                  leading: const Icon(Icons.file_download_outlined),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CategoryListPage(
                                cycleId: widget.cycleId,
                                type: 'received',
                              )),
                    );
                  },
                ),
              ),
              // const SizedBox(height: 10),
              // Container(
              //   decoration: BoxDecoration(
              //     border: Border.all(
              //       color: Colors.grey,
              //       width: 1.0,
              //     ),
              //     borderRadius: BorderRadius.circular(8.0),
              //   ),
              //   child: ListTile(
              //     title: const Text('Saving'),
              //     leading: const Icon(Icons.favorite),
              //     trailing: const Icon(Icons.arrow_forward_ios),
              //     onTap: () {
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //             builder: (context) => const SavingsPage()),
              //       );
              //     },
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
