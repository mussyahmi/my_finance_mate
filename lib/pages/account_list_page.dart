import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../models/cycle.dart';
import '../providers/accounts_provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/transactions_provider.dart';

class AccountListPage extends StatefulWidget {
  const AccountListPage({super.key});

  @override
  State<AccountListPage> createState() => _AccountListPageState();
}

class _AccountListPageState extends State<AccountListPage> {
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    if (context.read<CycleProvider>().cycle!.isLastCycle &&
        context.read<AccountsProvider>().accounts!.isEmpty &&
        context.read<TransactionsProvider>().transactions!.isNotEmpty) {
      EasyLoading.show(status: 'Moving your transactions... 🚀');

      await context.read<AccountsProvider>().migrateAccountFeature(context);

      EasyLoading.showSuccess('Done! Transactions moved. 🏁');
    }
  }

  @override
  Widget build(BuildContext context) {
    Cycle cycle = context.watch<CycleProvider>().cycle!;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverAppBar(
            title: Text('Account List'),
            centerTitle: true,
            scrolledUnderElevation: 9999,
            floating: true,
            snap: true,
          ),
        ],
        body: RefreshIndicator(
          onRefresh: () async {
            if (cycle.isLastCycle) {
              context
                  .read<AccountsProvider>()
                  .fetchAccounts(context, cycle, refresh: true);
            }
          },
          child: Center(
            child: FutureBuilder(
              future: context.watch<AccountsProvider>().getAccounts(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                      ],
                    ),
                  ); //* Display a loading indicator
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SelectableText(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'No accounts found.',
                      textAlign: TextAlign.center,
                    ),
                  ); //* Display a message for no accounts
                } else {
                  //* Display the list of accounts
                  final accounts = snapshot.data!;

                  return ListView.builder(
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      Account account = accounts[index];

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        margin: index == accounts.length - 1
                            ? const EdgeInsets.only(bottom: 80)
                            : null,
                        child: Card(
                          child: ListTile(
                            title: Text(account.name),
                            onTap: () =>
                                account.showAccountDetails(context, cycle),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
