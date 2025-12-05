// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../models/person.dart';
import '../providers/accounts_provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/person_provider.dart';
import '../providers/transactions_provider.dart';
import '../services/ad_cache_service.dart';
import '../services/ad_mob_service.dart';
import '../widgets/account_summary.dart';
import '../widgets/ad_container.dart';

class AccountListPage extends StatefulWidget {
  const AccountListPage({super.key});

  @override
  State<AccountListPage> createState() => _AccountListPageState();
}

class _AccountListPageState extends State<AccountListPage> {
  AdMobService? _adMobService;
  AdCacheService? _adCacheService;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    if (context.read<CycleProvider>().cycle!.isLastCycle &&
        context.read<AccountsProvider>().accounts!.isEmpty &&
        context.read<TransactionsProvider>().transactions!.isNotEmpty) {
      EasyLoading.show(
        dismissOnTap: false,
        status: 'Moving your transactions... 🚀',
      );

      await context.read<AccountsProvider>().migrateAccountFeature(context);

      EasyLoading.showSuccess('Done! Transactions moved. 🏁');
    }

    if (!kIsWeb) {
      _adMobService = context.read<AdMobService>();
      _adCacheService = context.read<AdCacheService>();
    }
  }

  @override
  Widget build(BuildContext context) {
    Person user = context.watch<PersonProvider>().user!;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: Text('Account List'),
            centerTitle: true,
            scrolledUnderElevation: 9999,
            floating: true,
            snap: true,
          ),
        ],
        body: Center(
          child: FutureBuilder(
            future: context.watch<AccountsProvider>().getAccounts(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: CircularProgressIndicator(),
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
                    Account account = accounts[index] as Account;

                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: AccountSummary(account: account),
                        ),
                        if (_adCacheService != null &&
                            !user.isPremium &&
                            (index == 1 || index == 7 || index == 13))
                          AdContainer(
                            adCacheService: _adCacheService!,
                            number: index,
                            adSize: AdSize.largeBanner,
                            adUnitId: _adMobService!.bannerAccountListAdUnitId!,
                            height: 100.0,
                          ),
                        if (index == accounts.length - 1)
                          const SizedBox(height: 80),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
