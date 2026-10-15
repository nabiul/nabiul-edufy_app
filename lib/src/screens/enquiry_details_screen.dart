import 'package:flutter/material.dart';
import '../models/enquiry.dart';
import '../services/api_client.dart';
import 'enquiry_form_screen.dart';

class EnquiryDetailsScreen extends StatefulWidget {
  const EnquiryDetailsScreen({required this.apiClient, required this.token, required this.enquiry, required this.options, required this.canEdit, super.key});
  final ApiClient apiClient; final String token; final Enquiry enquiry; final EnquiryOptions options; final bool canEdit;
  @override State<EnquiryDetailsScreen> createState() => _EnquiryDetailsScreenState();
}

class _EnquiryDetailsScreenState extends State<EnquiryDetailsScreen> {
  late Future<Enquiry> _future;
  @override void initState() { super.initState(); _future = widget.apiClient.enquiry(widget.token, widget.enquiry.id); }
  String _date(String? value) => value == null ? '—' : value.length >= 16 ? value.substring(0, 16).replaceFirst('T', ' ') : value;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Enquiry details'), actions: [if (widget.canEdit) IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () async { final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EnquiryFormScreen(apiClient: widget.apiClient, token: widget.token, options: widget.options, enquiry: widget.enquiry))); if (saved == true && mounted) setState(() => _future = widget.apiClient.enquiry(widget.token, widget.enquiry.id)); })]), body: FutureBuilder<Enquiry>(future: _future, builder: (context, snapshot) { if (!snapshot.hasData) return snapshot.hasError ? Center(child: Text(snapshot.error.toString())) : const Center(child: CircularProgressIndicator()); final item = snapshot.data!; return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [_info(item), const SizedBox(height: 16), const Text('Follow-up history', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 8), if (item.followUps.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No follow-up recorded yet.'))) else ...item.followUps.map((followUp) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: const Icon(Icons.phone_callback_rounded), title: Text(followUp.outcome?.isNotEmpty == true ? followUp.outcome! : 'Contact recorded'), subtitle: Text('${_date(followUp.contactedAt)}\n${followUp.notes ?? ''}\nNext: ${_date(followUp.nextFollowUpAt)}'), isThreeLine: true, trailing: Text(followUp.contactMethod ?? 'phone'))))]); }) );
  Widget _info(Enquiry item) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.studentName, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text('Status: ${item.status.replaceAll('_', ' ')}'), Text('Enquiry: ${item.number}'), Text('Guardian: ${item.guardianName ?? '—'}'), Text('Phone: ${item.phone}'), Text('Class: ${item.levelName ?? '—'}'), Text('Academic year: ${item.yearName ?? '—'}'), Text('Created: ${_date(item.createdAt)}'), if (item.notes?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Notes: ${item.notes}'))])));
}
