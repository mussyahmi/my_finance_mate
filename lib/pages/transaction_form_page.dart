// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:io';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';
import '../models/cycle.dart';
import '../models/person.dart';
import '../providers/accounts_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/person_provider.dart';
import '../providers/transactions_provider.dart';
import '../services/ad_mob_service.dart';
import '../services/message_services.dart';
import '../widgets/ad_container.dart';
import 'category_list_page.dart';
import 'image_view_page.dart';
import '../models/transaction.dart' as t;

class TransactionFormPage extends StatefulWidget {
  final String action;
  final t.Transaction? transaction;

  const TransactionFormPage({
    super.key,
    required this.action,
    this.transaction,
  });

  @override
  TransactionFormPageState createState() => TransactionFormPageState();
}

class TransactionFormPageState extends State<TransactionFormPage> {
  final MessageService messageService = MessageService();
  String selectedType = 'spent';
  String? selectedSubType;
  String? selectedCategoryId;
  List<Category> categories = [];
  String? selectedAccountId;
  String? selectedAccountToId;
  TextEditingController transactionAmountController = TextEditingController();
  TextEditingController transactionNoteController = TextEditingController();
  DateTime selectedDateTime = DateTime.now();
  bool _isLoading = false;
  List<dynamic> files = [];
  List<dynamic> filesToDelete = [];
  late AdMobService _adMobService;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adMobService = context.read<AdMobService>();

    if (!context.read<PersonProvider>().user!.isPremium) {
      _createInterstitialAd();
    }
  }

  Future<void> initAsync() async {
    await _fetchCategories();

    if (widget.transaction != null) {
      selectedType = widget.transaction!.type;
      selectedSubType = widget.transaction!.subType;
      transactionAmountController.text = widget.transaction!.amount;
      transactionNoteController.text =
          widget.transaction!.note.replaceAll('\\n', '\n');
      selectedDateTime = widget.transaction!.dateTime;
      files = widget.transaction!.files;

      await _fetchCategories();

      selectedCategoryId = widget.transaction!.categoryId.isEmpty
          ? null
          : widget.transaction!.categoryId;
      selectedAccountId = widget.transaction!.accountId;
      selectedAccountToId = widget.transaction!.accountToId.isEmpty
          ? null
          : widget.transaction!.accountToId;
    }
  }

  Future<void> _fetchCategories() async {
    List<Category> fetchedCategories = List<Category>.from(await context
        .read<CategoriesProvider>()
        .getCategories(context, selectedType, 'transaction_form'));

    setState(() {
      categories = fetchedCategories;
    });
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Person user = context.read<PersonProvider>().user!;
    Cycle cycle = context.watch<CycleProvider>().cycle!;

    return PopScope(
      canPop: !_isLoading,
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                title: Text('${widget.action} Transaction'),
                centerTitle: true,
                scrolledUnderElevation: 9999,
                floating: true,
                snap: true,
              ),
            ],
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDateTime,
                          firstDate: cycle.startDate,
                          lastDate: cycle.endDate,
                        );
                        if (selectedDate != null) {
                          final selectedTime = await showTimePicker(
                            context: context,
                            initialTime:
                                TimeOfDay.fromDateTime(selectedDateTime),
                          );
                          if (selectedTime != null) {
                            setState(() {
                              selectedDateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Date Time: ${DateFormat('EE, d MMM yyyy h:mm aa').format(selectedDateTime)}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton(
                      segments: const [
                        ButtonSegment(
                          value: 'spent',
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Spent'),
                          ),
                          icon: Icon(Icons.file_upload_outlined),
                        ),
                        ButtonSegment(
                          value: 'received',
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Received'),
                          ),
                          icon: Icon(Icons.file_download_outlined),
                        ),
                        ButtonSegment(
                          value: 'transfer',
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Transfer'),
                          ),
                          icon: Icon(Icons.swap_horiz),
                        ),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (newSelection) {
                        if (newSelection.first == 'transfer' &&
                            context.read<AccountsProvider>().accounts!.length <
                                2) {
                          EasyLoading.showInfo(
                              'You need at least 2 accounts to make a transfer.');
                          return;
                        }

                        setState(() {
                          selectedType = newSelection.first;
                          selectedCategoryId = null;
                          selectedAccountToId = null;
                        });

                        _fetchCategories();
                      },
                    ),
                    const SizedBox(height: 10),
                    if (selectedType == 'spent')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedButton(
                            segments: const [
                              ButtonSegment(
                                value: 'needs',
                                label: Text('Needs'),
                              ),
                              ButtonSegment(
                                value: 'wants',
                                label: Text('Wants'),
                              ),
                              ButtonSegment(
                                value: 'savings',
                                label: Text('Savings'),
                              ),
                            ],
                            selected: {selectedSubType},
                            onSelectionChanged: (newSelection) {
                              print(newSelection);
                              setState(() {
                                selectedSubType = newSelection.isNotEmpty
                                    ? newSelection.first
                                    : null;
                              });
                            },
                            emptySelectionAllowed: true,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    const SizedBox(height: 10),
                    DropdownSearch<String>(
                      selectedItem: selectedAccountId != null
                          ? context
                              .read<AccountsProvider>()
                              .getAccountById(selectedAccountId)
                              .name
                          : null,
                      onChanged: (newValue) async {
                        final selectedAccount = context
                            .read<AccountsProvider>()
                            .getAccountByName(newValue);

                        setState(() {
                          selectedAccountId = selectedAccount.id;
                          selectedAccountToId = null;
                        });
                      },
                      items: (filter, loadProps) {
                        return context
                            .read<AccountsProvider>()
                            .getFilteredAccountsByName(context, filter)
                            .map((account) => account.name)
                            .toList();
                      },
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: 'Account',
                        ),
                        baseStyle: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchDelay: const Duration(milliseconds: 500),
                        menuProps: MenuProps(surfaceTintColor: Colors.grey),
                        itemBuilder: (context, item, isDisabled, isSelected) {
                          return ListTile(title: Text(item));
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (selectedType != 'transfer')
                      Column(
                        children: [
                          DropdownSearch<String>(
                            selectedItem: selectedCategoryId != null
                                ? context
                                    .read<CategoriesProvider>()
                                    .getCategoryById(selectedCategoryId)
                                    .name
                                : null,
                            onChanged: (newValue) async {
                              if (newValue == 'add_new') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) {
                                    return CategoryListPage(
                                      type: selectedType,
                                      isFromTransactionForm: true,
                                    );
                                  }),
                                );

                                setState(() {
                                  selectedCategoryId = null;
                                });

                                await _fetchCategories();
                              } else {
                                final selectedCategory = context
                                    .read<CategoriesProvider>()
                                    .getCategoryByName(selectedType, newValue);

                                setState(() {
                                  selectedCategoryId = selectedCategory.id;
                                });
                              }
                            },
                            items: (filter, loadProps) {
                              final filteredCategories = categories
                                  .where((category) => category.name
                                      .toLowerCase()
                                      .contains(filter.toLowerCase()))
                                  .toList();

                              return [
                                'add_new',
                                ...filteredCategories
                                    .map((category) => category.name),
                              ];
                            },
                            decoratorProps: DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: 'Category',
                              ),
                              baseStyle: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchDelay: const Duration(milliseconds: 500),
                              menuProps:
                                  MenuProps(surfaceTintColor: Colors.grey),
                              itemBuilder:
                                  (context, item, isDisabled, isSelected) {
                                if (item == 'add_new') {
                                  return ListTile(
                                    leading: Icon(Icons.add_circle),
                                    title: Text('Add New'),
                                  );
                                } else {
                                  return ListTile(title: Text(item));
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    if (selectedType == 'transfer')
                      Column(
                        children: [
                          DropdownSearch<String>(
                            selectedItem: selectedAccountToId != null
                                ? context
                                    .read<AccountsProvider>()
                                    .getAccountById(selectedAccountToId)
                                    .name
                                : null,
                            onChanged: (newValue) async {
                              final selectedAccount = context
                                  .read<AccountsProvider>()
                                  .getAccountByName(newValue);

                              setState(() {
                                selectedAccountToId = selectedAccount.id;
                              });
                            },
                            items: (filter, loadProps) {
                              return context
                                  .read<AccountsProvider>()
                                  .getFilteredAccountsByName(context, filter)
                                  .where((account) =>
                                      account.id != selectedAccountId)
                                  .map((account) => account.name)
                                  .toList();
                            },
                            decoratorProps: DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: 'Transfer To',
                              ),
                              baseStyle: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchDelay: const Duration(milliseconds: 500),
                              menuProps:
                                  MenuProps(surfaceTintColor: Colors.grey),
                              itemBuilder:
                                  (context, item, isDisabled, isSelected) {
                                return ListTile(title: Text(item));
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    TextField(
                      controller: transactionAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: 'RM ',
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: transactionNoteController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 20),
                    const Text('Attachment:'),
                    if (files.isNotEmpty)
                      Column(
                        children: [
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (var index = 0;
                                    index < files.length;
                                    index++)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        //* Open a new screen with the larger image
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ImageViewPage(
                                              imageSource:
                                                  files[index] is String
                                                      ? files[index]
                                                      : files[index].path,
                                              type: files[index] is String
                                                  ? 'url'
                                                  : 'local',
                                            ),
                                          ),
                                        );
                                      },
                                      child: Stack(
                                        children: [
                                          if (files[index] is String)
                                            Image.network(
                                              files[index],
                                              height:
                                                  100, //* Adjust the height as needed
                                              fit: BoxFit.contain,
                                            )
                                          else
                                            Image.file(
                                              File(files[index].path!),
                                              height:
                                                  100, //* Adjust the height as needed
                                              fit: BoxFit.contain,
                                            ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: () {
                                                if (files[index] is String) {
                                                  setState(() {
                                                    filesToDelete = [
                                                      ...filesToDelete,
                                                      files[index]
                                                    ];
                                                  });
                                                }

                                                setState(() {
                                                  files.removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                color: Colors.red,
                                                child: const Icon(Icons.close),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        if (files.isNotEmpty && !user.isPremium) {
                          return EasyLoading.showInfo(
                              'Upgrade to Premium to unlock additional attachment slots.');
                        }

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
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      final file =
                                          await ImagePicker().pickImage(
                                        source: ImageSource.camera,
                                        imageQuality: 50,
                                      );

                                      if (file != null) {
                                        await _checkFileSize(
                                            file, await file.length());
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
                      child: const Text('Add Attachment'),
                    ),
                    const SizedBox(height: 30),
                    if (!user.isPremium)
                      Column(
                        children: [
                          AdContainer(
                            adMobService: _adMobService,
                            adSize: AdSize.largeBanner,
                            adUnitId:
                                _adMobService.bannerTransactionFormAdUnitId!,
                            height: 100.0,
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ElevatedButton(
                      onPressed: () async {
                        FocusManager.instance.primaryFocus?.unfocus();

                        if (_isLoading) return;

                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          EasyLoading.show(
                              status: widget.action == 'Edit'
                                  ? messageService.getRandomUpdateMessage()
                                  : messageService.getRandomAddMessage());

                          //* Get the values from the form
                          String type = selectedType;
                          String? subType = selectedSubType;
                          String? categoryId = selectedCategoryId;
                          String? accountId = selectedAccountId;
                          String? accountToId = selectedAccountToId;
                          String amount = transactionAmountController.text;
                          String note = transactionNoteController.text
                              .replaceAll('\n', '\\n');
                          DateTime dateTime = selectedDateTime;

                          //* Validate the form data
                          final message = _validate(
                              accountId, type, categoryId, accountToId, amount);

                          if (message.isNotEmpty) {
                            EasyLoading.showInfo(message);
                            return;
                          }

                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          int? transactionActionCounter =
                              prefs.getInt('transaction_action_counter');

                          if (transactionActionCounter == null) {
                            await prefs.setInt('transaction_action_counter', 0);
                            transactionActionCounter = 0;
                          }

                          transactionActionCounter += 1;
                          await prefs.setInt('transaction_action_counter',
                              transactionActionCounter);

                          print(transactionActionCounter);

                          if (transactionActionCounter >= 3 &&
                              !user.isPremium) {
                            _showInterstitialAd(prefs);
                          }

                          await context
                              .read<TransactionsProvider>()
                              .updateTransaction(
                                context,
                                widget.action,
                                dateTime,
                                type,
                                subType,
                                categoryId,
                                accountId!,
                                accountToId,
                                amount,
                                note,
                                files,
                                filesToDelete,
                                widget.transaction,
                              );

                          EasyLoading.showSuccess(widget.action == 'Edit'
                              ? messageService.getRandomDoneUpdateMessage()
                              : messageService.getRandomDoneAddMessage());

                          Navigator.of(context).pop(true);
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.onPrimary,
                                strokeWidth: 2.0,
                              ),
                            )
                          : const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _validate(String? accountId, String type, String? categoryId,
      String? accountToId, String amount) {
    if (accountId == null || accountId.isEmpty) {
      return 'Please choose an account.';
    }

    if (type != 'transfer') {
      if (categoryId == null || categoryId.isEmpty) {
        return 'Please choose a category.';
      }
    } else {
      if (accountToId == null || accountToId.isEmpty) {
        return 'Please choose an account to transfer to.';
      }
    }

    if (amount.isEmpty) {
      return 'Please enter the transaction\'s amount.';
    }

    //* Remove any commas from the string
    String cleanedValue = amount.replaceAll(',', '');

    //* Check if the cleaned value is a valid double
    if (double.tryParse(cleanedValue) == null) {
      return 'Please enter a valid number.';
    }

    //* Check if the value is a positive number
    if (double.parse(cleanedValue) <= 0) {
      return 'Please enter a positive value.';
    }

    //* Custom currency validation (you can modify this based on your requirements)
    //* Here, we are checking if the value has up to 2 decimal places
    List<String> splitValue = cleanedValue.split('.');
    if (splitValue.length > 1 && splitValue[1].length > 2) {
      return 'Please enter a valid currency value with up to 2 decimal places';
    }

    transactionAmountController.text = cleanedValue;

    return '';
  }

  Future<void> _checkFileSize(dynamic file, int fileSize) async {
    if (fileSize <= 5 * 1024 * 1024) {
      setState(() {
        files = [...files, file];
      });
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

  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _adMobService.interstitialTransactionFormAdUnitId!,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void _showInterstitialAd(SharedPreferences prefs) async {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _createInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _createInterstitialAd();
        },
      );

      await _interstitialAd!.show();
      await prefs.setInt('transaction_action_counter', 0);
      _interstitialAd = null;
    }
  }
}
