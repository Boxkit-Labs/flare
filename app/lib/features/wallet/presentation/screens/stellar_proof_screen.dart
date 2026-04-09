import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/core/theme/app_theme.dart';
import 'package:flare_app/core/models/models.dart';
import 'package:flare_app/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flare_app/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class StellarProofScreen extends StatefulWidget {
  const StellarProofScreen({super.key});

  @override
  State<StellarProofScreen> createState() => _StellarProofScreenState();
}

class _StellarProofScreenState extends State<StellarProofScreen> {
  String _filter = 'all'; // all, findings, verification, collaboration

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Stellar Proof Wall', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _exportHashes(context),
          ),
        ],
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state is WalletLoaded) {
            final filteredTxs = _getFilteredTransactions(state.transactions);
            final totalUsdc = state.transactions.fold(0.0, (sum, tx) => sum + tx.amountUsdc);

            return Column(
              children: [
                _buildHeaderStats(state.transactions, totalUsdc, state.wallet?.publicKey ?? 'G...'),
                _buildFilterBar(),
                Expanded(
                  child: filteredTxs.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredTxs.length,
                          itemBuilder: (context, index) => _buildTransactionCard(filteredTxs[index]),
                        ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> txs) {
    if (_filter == 'all') return txs;
    if (_filter == 'findings') return txs.where((tx) => tx.findingDetected == true).toList();
    if (_filter == 'on_chain') return txs.where((tx) => !tx.isOffChain).toList();
    if (_filter == 'off_chain') return txs.where((tx) => tx.isOffChain).toList();
    return txs.where((tx) => tx.txType == _filter).toList();
  }

  Widget _buildHeaderStats(List<TransactionModel> txs, double usdc, String wallet) {
    final offChainCount = txs.where((t) => t.isOffChain).length;
    final feesSavedXlm = offChainCount * 0.0001; // Standard fee approximation

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('TOTAL TXs', txs.length.toString()),
              _buildStatItem('FEES SAVED', '${feesSavedXlm.toStringAsFixed(4)} XLM', color: Colors.tealAccent),
              _buildStatItem('NETWORK', 'TESTNET', color: Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Wallet: ${wallet.substring(0, 8)}...${wallet.substring(wallet.length - 8)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Colors.white54, size: 16),
                onPressed: () {
                   Clipboard.setData(ClipboardData(text: wallet));
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied')));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ],
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          _buildFilterChip('Findings', 'findings'),
          _buildFilterChip('On-chain', 'on_chain'),
          _buildFilterChip('Off-chain', 'off_chain'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        selected: isSelected,
        onSelected: (selected) {
           if (selected) setState(() => _filter = value);
        },
        selectedColor: AppTheme.primary,
        labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.black12),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _getTypeIcon(tx.txType, tx.findingDetected ?? false),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.watcherName ?? tx.serviceName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      Text(DateFormat('MMM dd, HH:mm').format(DateTime.parse(tx.timestamp)), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Text('-\$${tx.amountUsdc.toStringAsFixed(3)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.redAccent)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tx.stellarTxHash,
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => Clipboard.setData(ClipboardData(text: tx.stellarTxHash)),
                  child: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               _buildBadge(tx.txType, tx.findingDetected ?? false, tx.isOffChain),
               tx.isOffChain 
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt_rounded, size: 14, color: Colors.purple),
                          SizedBox(width: 4),
                          Text('MPP Batched', style: TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : TextButton.icon(
                     onPressed: () => _launchExplorer(tx.stellarTxHash),
                     icon: const Icon(Icons.open_in_new_rounded, size: 14),
                     label: const Text('Verify on Explorer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                   ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getTypeIcon(String type, bool detected) {
    if (detected) return const Text('⭐', style: TextStyle(fontSize: 18));
    switch (type) {
      case 'verification': return const Text('🛡️', style: TextStyle(fontSize: 18));
      case 'collaboration': return const Text('🔗', style: TextStyle(fontSize: 18));
      default: return const Text('⚡', style: TextStyle(fontSize: 18));
    }
  }

  Widget _buildBadge(String type, bool detected, bool isOffChain) {
    String label = 'CHECK';
    Color color = Colors.grey;
    
    if (detected) {
      label = 'FINDING'; color = Colors.amber;
    } else if (isOffChain) {
      label = 'M-PROOF'; color = Colors.purpleAccent;
    } else if (type == 'verification') {
      label = 'VERIFIED'; color = Colors.blueAccent;
    } else if (type == 'collaboration') {
      label = 'CROSS-CHECK'; color = Colors.tealAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _buildEmptyState() {
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(Icons.history_rounded, size: 64, color: Colors.black.withValues(alpha: 0.1)),
           const SizedBox(height: 16),
           const Text('No transactions found', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
         ],
       ),
     );
  }

  void _launchExplorer(String hash) async {
    final url = Uri.parse('https://stellar.expert/explorer/testnet/tx/$hash');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _exportHashes(BuildContext context) {
    final state = context.read<WalletBloc>().state;
    if (state is WalletLoaded) {
      final list = state.transactions.map((tx) => '${tx.timestamp} | \$${tx.amountUsdc} | ${tx.stellarTxHash}').join('\n');
      Share.share('Flare Stellar Audit Log:\n\n$list', subject: 'Flare Stellar Proof');
    }
  }
}
