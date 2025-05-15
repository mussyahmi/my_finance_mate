import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/person.dart';
import '../pages/image_view_page.dart';
import '../providers/person_provider.dart';
import '../services/message_services.dart';

class ProfileImage extends StatefulWidget {
  const ProfileImage({super.key});

  @override
  State<ProfileImage> createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage> {
  final MessageService messageService = MessageService();

  @override
  Widget build(BuildContext context) {
    Person user = context.watch<PersonProvider>().user!;

    return Column(
      children: [
        Stack(children: [
          GestureDetector(
            onTap: user.imageUrl.isNotEmpty
                ? () {
                    //* Open a new screen with the larger image
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageViewPage(
                          files: [user.imageUrl],
                          index: 0,
                        ),
                      ),
                    );
                  }
                : null,
            child: Container(
              width: 150, // Adjust as needed
              height: 150, // Adjust as needed
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: user.imageUrl.isNotEmpty
                      ? NetworkImage(user.imageUrl)
                      : AssetImage('assets/icon/icon.png') as ImageProvider,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: IconButton.filledTonal(
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text(
                        'Choose Option',
                        textAlign: TextAlign.center,
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                            onPressed: () async {
                              Navigator.of(context).pop();
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.image,
                              );
                              if (result != null) {
                                PlatformFile file = result.files.first;

                                await _checkFileSize(file, file.size);
                              }
                            },
                            child: const Text('Pick from Gallery'),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                            onPressed: () async {
                              Navigator.of(context).pop();
                              final file = await ImagePicker().pickImage(
                                source: ImageSource.camera,
                                imageQuality: 50,
                              );

                              if (file != null) {
                                await _checkFileSize(file, await file.length());
                              }
                            },
                            child: const Text('Take a Photo'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              icon: Icon(
                CupertinoIcons.pencil,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        ]),
      ],
    );
  }

  Future<void> _checkFileSize(dynamic file, int fileSize) async {
    if (fileSize <= 5 * 1024 * 1024) {
      EasyLoading.show(status: messageService.getRandomUpdateMessage());

      await context.read<PersonProvider>().uploadProfileImage(file);

      EasyLoading.showSuccess(messageService.getRandomDoneUpdateMessage());
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('File Size Limit Exceeded'),
            content: Text(
                'The file ${file.name} exceeds 5MB and cannot be uploaded.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }
}
