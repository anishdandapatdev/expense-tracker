import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/features/settings/controllers/currency_controller.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
import 'package:expense_tracker/features/friends_money/models/friends_money_model.dart';
import 'package:expense_tracker/features/friends_money/controllers/friends_money_controller.dart';

class AddFriendMoneyScreen extends HookConsumerWidget {
  static const String routeName = '/add-friend-money';
  
  final String initialType;

  const AddFriendMoneyScreen({super.key, this.initialType = 'Lent'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final amountController = useTextEditingController(text: "0");
    final friendNameController = useTextEditingController();
    final noteController = useTextEditingController();
        
    final selectedType = useState<String>(initialType); // 'Lent' or 'Borrowed'
    final selectedDate = useState<DateTime>(DateTime.now());
    final currentCurrency = ref.watch(currencyProvider);

    final accentColor = selectedType.value == 'Borrowed' ? const Color(0xFFEF4444) : const Color(0xFF007A3D);
    final isSaving = useState<bool>(false);

    void saveRecord() async {
      if (isSaving.value) return; // Prevent double-tap
      if (formKey.currentState!.validate()) {
        isSaving.value = true;
        final amount = double.tryParse(amountController.text) ?? 0.0;
        final user = ref.read(authStateProvider).value;

        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to add a record')),
          );
          isSaving.value = false;
          return;
        }

        final recordType = selectedType.value.toLowerCase(); // 'lent' or 'borrowed'

        final record = FriendMoneyModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user.uid,
          friendName: friendNameController.text,
          type: recordType,
          amount: amount,
          date: selectedDate.value,
          note: noteController.text,
          isSettled: false,
        );

        try {
          ref.read(friendMoneyControllerProvider).addFriendMoney(record);
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Record added!')),
            );
          }
        } catch (e) {
          isSaving.value = false;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF007A3D),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Add Record",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Lent',
                  label: Text('I Lent'),
                  icon: Icon(Icons.call_made, size: 18),
                ),
                ButtonSegment(
                  value: 'Borrowed',
                  label: Text('I Borrowed'),
                  icon: Icon(Icons.call_received, size: 18),
                ),
              ],
              selected: {selectedType.value},
              onSelectionChanged: (newSelection) {
                selectedType.value = newSelection.first;
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) return Colors.white;
                  return Colors.white.withValues(alpha: 0.3);
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) return accentColor;
                  return Colors.white;
                }),
                side: WidgetStateProperty.all(BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              // Amount Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Set Amount",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        decoration: InputDecoration(
                          prefixText: '${currentCurrency.symbol} ',
                          prefixStyle: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty || double.tryParse(value) == 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Details Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: friendNameController,
                        decoration: const InputDecoration(
                          hintText: "Friend's Name",
                          prefixIcon: Icon(Icons.person, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: const TextStyle(fontSize: 16),
                        validator: (value) => (value == null || value.isEmpty) ? "Enter friend's name" : null,
                      ),
                      const Divider(),
                      TextFormField(
                        controller: noteController,
                        decoration: const InputDecoration(
                          hintText: "Note (Optional)",
                          prefixIcon: Icon(Icons.edit_note, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Divider(),
                      InkWell(
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate.value,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) selectedDate.value = picked;
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.grey),
                              const SizedBox(width: 15),
                              Text(
                                DateFormat('dd MMMM yyyy').format(selectedDate.value),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Spacer(),
                              const Text(
                                "Set Date",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: isSaving.value ? null : saveRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                  ),
                  child: isSaving.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "SAVE RECORD",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
