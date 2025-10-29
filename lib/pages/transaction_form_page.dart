// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import '../models/category.dart';
import '../models/cycle.dart';
import '../models/person.dart';
import '../providers/accounts_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/person_provider.dart';
import '../providers/transactions_provider.dart';
import '../services/ad_cache_service.dart';
import '../services/ad_mob_service.dart';
import '../services/message_services.dart';
import '../widgets/ad_container.dart';
import '../widgets/tag.dart';
import 'amount_input_page.dart';
import 'image_view_page.dart';
import '../models/transaction.dart' as t;
import 'note_input_page.dart';
import 'premium_access_page.dart';

class TransactionFormPage extends StatefulWidget {
  final String action;
  final String? selectedCategoryId;
  final t.Transaction? transaction;
  final bool? isTourMode;
  final BuildContext showcaseContext;

  const TransactionFormPage({
    super.key,
    required this.action,
    this.selectedCategoryId,
    this.transaction,
    required this.isTourMode,
    required this.showcaseContext,
  });

  @override
  TransactionFormPageState createState() => TransactionFormPageState();
}

class TransactionFormPageState extends State<TransactionFormPage> {
  final MessageService messageService = MessageService();
  String selectedType = 'spent';
  String? selectedCategoryId;
  List<Category> categories = [];
  String? selectedAccountId;
  String? selectedAccountToId;
  final TextEditingController _transactionAmountController =
      TextEditingController();
  final TextEditingController _transactionNoteController =
      TextEditingController();
  DateTime selectedDateTime = DateTime.now();
  bool _isLoading = false;
  List<dynamic> files = [];
  List<dynamic> filesToDelete = [];
  late AdMobService _adMobService;
  late AdCacheService _adCacheService;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  int freemiumAttachmentSlots = 1;
  final GlobalKey _tourTransactionForm1 = GlobalKey();
  final GlobalKey _tourTransactionForm2 = GlobalKey();
  final GlobalKey _tourTransactionForm3 = GlobalKey();
  final GlobalKey _tourTransactionForm4 = GlobalKey();
  final GlobalKey _tourTransactionForm5 = GlobalKey();
  final GlobalKey _tourTransactionForm6 = GlobalKey();
  final GlobalKey _tourTransactionForm7 = GlobalKey();

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adMobService = context.read<AdMobService>();
    _adCacheService = context.read<AdCacheService>();

    if (!context.read<PersonProvider>().user!.isPremium) {
      _createInterstitialAd();
      _createRewardedAd();
    }
  }

  Future<void> initAsync() async {
    await _fetchCategories();

    if (widget.selectedCategoryId != null) {
      selectedCategoryId = widget.selectedCategoryId;
    }

    if (widget.transaction != null) {
      selectedType = widget.transaction!.type;
      _transactionAmountController.text = widget.transaction!.amount;
      _transactionNoteController.text = widget.transaction!.note;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isTourMode == true) {
        ShowCaseWidget.of(widget.showcaseContext).startShowCase([
          _tourTransactionForm1,
          _tourTransactionForm2,
          _tourTransactionForm3,
          _tourTransactionForm4,
          _tourTransactionForm5,
          _tourTransactionForm6,
          _tourTransactionForm7,
        ]);
      }
    });
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
    _rewardedAd?.dispose();
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
                    Showcase(
                      key: _tourTransactionForm1,
                      description:
                          'Select the date and time for the transaction. You can also change the date and time later.',
                      disableBarrierInteraction: true,
                      disposeOnTap: false,
                      onTargetClick: () {},
                      tooltipActions: [
                        TooltipActionButton(
                          type: TooltipDefaultActionType.next,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                      tooltipActionConfig: TooltipActionConfig(
                        position: TooltipActionPosition.outside,
                        alignment: MainAxisAlignment.end,
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          FocusManager.instance.primaryFocus?.unfocus();

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
                    ),
                    const SizedBox(height: 10),
                    Showcase(
                      key: _tourTransactionForm2,
                      description:
                          'Select the type of transaction: Spent, Received, or Transfer. Spent is for expenses, Received is for income, and Transfer is for moving money between accounts.',
                      disableBarrierInteraction: true,
                      disposeOnTap: false,
                      onTargetClick: () {},
                      tooltipActions: [
                        TooltipActionButton(
                          type: TooltipDefaultActionType.previous,
                          backgroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        TooltipActionButton(
                          type: TooltipDefaultActionType.next,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                      tooltipActionConfig: TooltipActionConfig(
                        position: TooltipActionPosition.outside,
                      ),
                      child: SegmentedButton(
                        segments: const [
                          ButtonSegment(
                            value: 'spent',
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Spent'),
                            ),
                            icon: Icon(CupertinoIcons.tray_arrow_up_fill),
                          ),
                          ButtonSegment(
                            value: 'received',
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Received'),
                            ),
                            icon: Icon(CupertinoIcons.tray_arrow_down_fill),
                          ),
                          ButtonSegment(
                            value: 'transfer',
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Transfer'),
                            ),
                            icon: Icon(CupertinoIcons.arrow_right_arrow_left),
                          ),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (newSelection) {
                          FocusManager.instance.primaryFocus?.unfocus();

                          if (newSelection.first == 'transfer' &&
                              context
                                      .read<AccountsProvider>()
                                      .accounts!
                                      .length <
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
                    ),
                    const SizedBox(height: 10),
                    Showcase(
                      key: _tourTransactionForm3,
                      description:
                          'Select the account for the transaction. If you are transferring money, select the account to transfer from. If you are spending or receiving money, select the account where the money is coming from or going to.',
                      disableBarrierInteraction: true,
                      disposeOnTap: false,
                      onTargetClick: () {},
                      tooltipActions: [
                        TooltipActionButton(
                          type: TooltipDefaultActionType.previous,
                          backgroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        TooltipActionButton(
                          type: TooltipDefaultActionType.next,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                      tooltipActionConfig: TooltipActionConfig(
                        position: TooltipActionPosition.outside,
                      ),
                      child: DropdownSearch<String>(
                        selectedItem: selectedAccountId != null
                            ? context
                                .read<AccountsProvider>()
                                .getAccountById(selectedAccountId)
                                .name
                            : null,
                        onChanged: (newValue) async {
                          FocusManager.instance.primaryFocus?.unfocus();

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
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search accounts...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          itemBuilder: (context, item, isDisabled, isSelected) {
                            return ListTile(title: Text(item));
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (selectedType != 'transfer')
                      Column(
                        children: [
                          Showcase(
                            key: _tourTransactionForm4,
                            description:
                                'Select the category for the transaction. Categories help you organize your transactions and track your spending. You can create new categories in the Categories page.',
                            disableBarrierInteraction: true,
                            disposeOnTap: false,
                            onTargetClick: () {},
                            tooltipActions: [
                              TooltipActionButton(
                                type: TooltipDefaultActionType.previous,
                                backgroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                textStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              TooltipActionButton(
                                type: TooltipDefaultActionType.next,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                textStyle: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ],
                            tooltipActionConfig: TooltipActionConfig(
                              position: TooltipActionPosition.outside,
                            ),
                            child: DropdownSearch<String>(
                              selectedItem: selectedCategoryId != null
                                  ? context
                                      .read<CategoriesProvider>()
                                      .getCategoryById(selectedCategoryId)
                                      .name
                                  : null,
                              onChanged: (newValue) async {
                                FocusManager.instance.primaryFocus?.unfocus();

                                final selectedCategory = context
                                    .read<CategoriesProvider>()
                                    .getCategoryByName(selectedType, newValue);

                                setState(() {
                                  selectedCategoryId = selectedCategory.id;
                                });
                              },
                              items: (filter, loadProps) {
                                final filteredCategories = categories
                                    .where((category) => category.name
                                        .toLowerCase()
                                        .contains(filter.toLowerCase()))
                                    .toList();

                                return [
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
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: 'Search categories...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                                itemBuilder:
                                    (context, item, isDisabled, isSelected) {
                                  return ListTile(
                                    title: Row(
                                      children: [
                                        if (selectedType == 'spent')
                                          Row(
                                            children: [
                                              Tag(
                                                title: context
                                                    .read<CategoriesProvider>()
                                                    .getCategoryByName(
                                                        selectedType, item)
                                                    .subType,
                                              ),
                                              SizedBox(width: 10),
                                            ],
                                          ),
                                        Text(item),
                                      ],
                                    ),
                                  );
                                },
                              ),
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
                              FocusManager.instance.primaryFocus?.unfocus();

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
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: 'Search accounts...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                              itemBuilder:
                                  (context, item, isDisabled, isSelected) {
                                return ListTile(title: Text(item));
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    Showcase(
                      key: _tourTransactionForm5,
                      description:
                          'Enter the amount for the transaction. For transfers, this is the amount being transferred. For spent or received transactions, this is the amount spent or received.',
                      disableBarrierInteraction: true,
                      disposeOnTap: false,
                      onTargetClick: () {},
                      tooltipActions: [
                        TooltipActionButton(
                          type: TooltipDefaultActionType.previous,
                          backgroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        TooltipActionButton(
                          type: TooltipDefaultActionType.next,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                      tooltipActionConfig: TooltipActionConfig(
                        position: TooltipActionPosition.outside,
                      ),
                      child: GestureDetector(
                        onTap: () async {
                          FocusManager.instance.primaryFocus?.unfocus();

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AmountInputPage(
                                amount: _transactionAmountController.text,
                              ),
                            ),
                          );

                          if (result != null && result is String) {
                            _transactionAmountController.text = result;
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _transactionAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              prefixText: 'RM',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Showcase(
                      key: _tourTransactionForm6,
                      description:
                          'Add a note for the transaction. This can be any additional information you want to remember about the transaction.',
                      disableBarrierInteraction: true,
                      disposeOnTap: false,
                      onTargetClick: () {},
                      tooltipActions: [
                        TooltipActionButton(
                          type: TooltipDefaultActionType.previous,
                          backgroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        TooltipActionButton(
                          type: TooltipDefaultActionType.next,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                      tooltipActionConfig: TooltipActionConfig(
                        position: TooltipActionPosition.outside,
                      ),
                      child: Card(
                        child: ListTile(
                          onTap: () async {
                            final String? note = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NoteInputPage(
                                  note: _transactionNoteController.text,
                                ),
                              ),
                            );

                            if (note == null) {
                              return;
                            }

                            if (note == 'empty') {
                              setState(() {
                                _transactionNoteController.text = '';
                              });
                            } else if (note.isNotEmpty) {
                              setState(() {
                                _transactionNoteController.text = note;
                              });
                            }
                          },
                          leading: Icon(Icons.notes),
                          title: Text(
                            _transactionNoteController.text.isEmpty
                                ? 'Add Note'
                                : _transactionNoteController.text
                                        .contains('insert')
                                    ? ParchmentDocument.fromJson(jsonDecode(
                                            _transactionNoteController.text))
                                        .toPlainText()
                                    : _transactionNoteController.text
                                        .split('\\n')[0],
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text('Attachment:'),
                        if (!user.isPremium && freemiumAttachmentSlots > 1)
                          Text(
                            ' (${files.length}/$freemiumAttachmentSlots) in use',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                            ),
                          ),
                      ],
                    ),
                    if (files.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();

                                        //* Open a new screen with the larger image
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ImageViewPage(
                                              files: files,
                                              index: index,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Stack(
                                        children: [
                                          if (files[index] is String)
                                            CachedNetworkImage(
                                              imageUrl: files[index],
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Icon(Icons.error),
                                              height: 100,
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
                                                FocusManager
                                                    .instance.primaryFocus
                                                    ?.unfocus();

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
                                                child: const Icon(
                                                    CupertinoIcons.clear),
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
                    Showcase(
                      key: _tourTransactionForm7,
                      description:
                          'Add attachments to the transaction. You can add images related to the transaction. You can add up to 3 attachments for free, or unlock unlimited attachment slots by upgrading to Premium.',
                      disableBarrierInteraction: true,
                      disposeOnTap: false,
                      onTargetClick: () {},
                      tooltipActions: [
                        TooltipActionButton(
                          type: TooltipDefaultActionType.previous,
                          backgroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        TooltipActionButton(
                          name: 'Got it',
                          type: TooltipDefaultActionType.next,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                      tooltipActionConfig: TooltipActionConfig(
                        position: TooltipActionPosition.outside,
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          FocusManager.instance.primaryFocus?.unfocus();

                          if (!user.isPremium) {
                            if (files.isNotEmpty &&
                                freemiumAttachmentSlots == 1) {
                              return showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text(
                                        'Unlock More Attachment Slots!'),
                                    content: const Text(
                                        'Want to add more attachments? You can upload up to 3 attachments for this transaction by watching a quick ad, or unlock unlimited additional attachment slots by upgrading to Premium!'),
                                    actions: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          foregroundColor: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        ),
                                        onPressed: () {
                                          if (!user.isPremium) {
                                            _showRewardedAd();
                                          }

                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Watch Ad'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          surfaceTintColor: Colors.orange,
                                          foregroundColor: Colors.orangeAccent,
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const PremiumSubscriptionPage(),
                                            ),
                                          );
                                        },
                                        child: const Text('Upgrade to Premium'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Later'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else if (files.length ==
                                freemiumAttachmentSlots) {
                              return showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text(
                                        'Maximum Attachments Reached!'),
                                    content: const Text(
                                        'You have reached the maximum number of attachments for this transaction. Please upgrade to Premium to unlock unlimited additional attachment slots.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Later'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          surfaceTintColor: Colors.orange,
                                          foregroundColor: Colors.orangeAccent,
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const PremiumSubscriptionPage(),
                                            ),
                                          );
                                        },
                                        child: const Text('Upgrade to Premium'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
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
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        final result =
                                            await FilePicker.platform.pickFiles(
                                          type: FileType.image,
                                        );
                                        if (result != null) {
                                          PlatformFile file =
                                              result.files.first;

                                          await _checkFileSize(file, file.size);
                                        }
                                      },
                                      child: const Text('Pick from Gallery'),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
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
                    ),
                    const SizedBox(height: 30),
                    if (!user.isPremium)
                      Column(
                        children: [
                          AdContainer(
                            adCacheService: _adCacheService,
                            number: 1,
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
                            dismissOnTap: false,
                            status: widget.action == 'Edit'
                                ? messageService.getRandomUpdateMessage()
                                : messageService.getRandomAddMessage(),
                          );

                          //* Get the values from the form
                          String type = selectedType;
                          String? categoryId = selectedCategoryId;
                          String? accountId = selectedAccountId;
                          String? accountToId = selectedAccountToId;
                          String amount = _transactionAmountController.text;
                          String note = _transactionNoteController.text;
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
    if (double.parse(cleanedValue) < 0) {
      return 'Please enter a positive value.';
    }

    //* Check if the value is 0
    if (double.parse(cleanedValue) == 0) {
      return 'The amount cannot be zero.';
    }

    //* Custom currency validation (you can modify this based on your requirements)
    //* Here, we are checking if the value has up to 2 decimal places
    List<String> splitValue = cleanedValue.split('.');
    if (splitValue.length > 1 && splitValue[1].length > 2) {
      return 'Please enter a valid currency value with up to 2 decimal places';
    }

    _transactionAmountController.text = cleanedValue;

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

  void _createRewardedAd() {
    RewardedAd.load(
      adUnitId: _adMobService.rewardedFreemiumAttachmentSlotsAdUnitId!,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
          });
        },
        onAdFailedToLoad: (error) {
          setState(() {
            _rewardedAd = null;
          });
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _createRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          EasyLoading.showInfo('Failed to show ad. Please try again later.');
          ad.dispose();
          _createRewardedAd();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) async {
          setState(() {
            freemiumAttachmentSlots = 3;
          });

          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Reward Granted!'),
                content: const Text(
                    'You\'re good to go! You can upload up to 3 attachments for this transaction. Keep everything in one place! 🚀'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }
}
