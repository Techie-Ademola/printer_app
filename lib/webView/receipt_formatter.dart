// import 'package:flutter/material.dart';

//   // Class to store format information for ranges of text
//   class TextFormat {
//     final int start;
//     final int end;
//     final bool isBold;
//     final bool isItalic;
//     final bool isUnderlined;
//     final TextAlign alignment;

//     TextFormat({
//       required this.start,
//       required this.end,
//       this.isBold = false,
//       this.isItalic = false,
//       this.isUnderlined = false,
//       this.alignment = TextAlign.left,
//     });
//   }

// class ReceiptFormatter extends StatefulWidget {
//   const ReceiptFormatter({Key? key}) : super(key: key);

//   @override
//   _ReceiptFormatterState createState() => _ReceiptFormatterState();
// }

// class _ReceiptFormatterState extends State<ReceiptFormatter> {
//   final TextEditingController _textController = TextEditingController();
//   final ValueNotifier<String> _formattedText = ValueNotifier<String>('');
  
//   // Track current formatting and selection
//   TextSelection? _currentSelection;
//   List<TextFormat> _formatRanges = [];
//   double _fontSize = 16.0;

//   @override
//   void initState() {
//     super.initState();
//     _textController.addListener(_updateFormattedPreview);
//   }

//   void _updateFormattedPreview() {
//     _formattedText.value = _textController.text;
//   }



//   void _applyFormatting({
//     bool? isBold,
//     bool? isItalic,
//     bool? isUnderlined,
//     TextAlign? alignment,
//   }) {
//     if (_currentSelection == null || _currentSelection!.isCollapsed) return;

//     setState(() {
//       // Remove any existing formatting in the selected range
//       _formatRanges.removeWhere((format) =>
//           (format.start >= _currentSelection!.start && format.end <= _currentSelection!.end));

//       // Add new formatting
//       _formatRanges.add(TextFormat(
//         start: _currentSelection!.start,
//         end: _currentSelection!.end,
//         isBold: isBold ?? false,
//         isItalic: isItalic ?? false,
//         isUnderlined: isUnderlined ?? false,
//         alignment: alignment ?? TextAlign.left,
//       ));

//       // Sort ranges by start position
//       _formatRanges.sort((a, b) => a.start.compareTo(b.start));
//     });
//   }

//   TextSpan _buildFormattedText(String text) {
//     if (_formatRanges.isEmpty) {
//       return TextSpan(text: text, style: TextStyle(color: Colors.black));
//     }

//     List<TextSpan> spans = [];
//     int currentIndex = 0;

//     for (var format in _formatRanges) {
//       // Add unformatted text before this range
//       if (currentIndex < format.start) {
//         spans.add(TextSpan(
//           text: text.substring(currentIndex, format.start),
//           style: TextStyle(color: Colors.black),
//         ));
//       }

//       // Add formatted text
//       spans.add(TextSpan(
//         text: text.substring(format.start, format.end),
//         style: TextStyle(
//           color: Colors.black,
//           fontWeight: format.isBold ? FontWeight.bold : FontWeight.normal,
//           fontStyle: format.isItalic ? FontStyle.italic : FontStyle.normal,
//           decoration: format.isUnderlined ? TextDecoration.underline : TextDecoration.none,
//         ),
//       ));

//       currentIndex = format.end;
//     }

//     // Add any remaining unformatted text
//     if (currentIndex < text.length) {
//       spans.add(TextSpan(
//         text: text.substring(currentIndex),
//         style: TextStyle(color: Colors.black),
//       ));
//     }

//     return TextSpan(children: spans);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Formatting toolbar
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           decoration: BoxDecoration(
//             color: const Color(0xff0a0203),
//             border: Border(
//               bottom: BorderSide(color: Colors.grey.shade700),
//             ),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               DropdownButton<String>(
//                 value: 'Heading 2',
//                 dropdownColor: const Color(0xff0a0203),
//                 style: const TextStyle(color: Colors.white),
//                 items: ['Heading 1', 'Heading 2', 'Heading 3']
//                     .map((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) {
//                   if (newValue != null) {
//                     setState(() {
//                       _fontSize = newValue == 'Heading 1'
//                           ? 20.0
//                           : newValue == 'Heading 2'
//                               ? 16.0
//                               : 14.0;
//                     });
//                   }
//                 },
//               ),
//               Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.format_bold, color: Colors.white),
//                     onPressed: () => _applyFormatting(isBold: true),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.format_italic, color: Colors.white),
//                     onPressed: () => _applyFormatting(isItalic: true),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.format_underline, color: Colors.white),
//                     onPressed: () => _applyFormatting(isUnderlined: true),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.format_align_left, color: Colors.white),
//                     onPressed: () => _applyFormatting(alignment: TextAlign.left),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.format_align_center, color: Colors.white),
//                     onPressed: () => _applyFormatting(alignment: TextAlign.center),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.format_align_right, color: Colors.white),
//                     onPressed: () => _applyFormatting(alignment: TextAlign.right),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
        
//         // Text input field
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
//           child: TextField(
//             controller: _textController,
//             style: TextStyle(
//               fontSize: _fontSize,
//               color: Colors.white,
//             ),
//             maxLines: 5,
//             minLines: 5,
//             cursorColor: Colors.white,
//             keyboardType: TextInputType.multiline,
//             textInputAction: TextInputAction.newline,
//             onChanged: (value) {
//               setState(() {});
//             },
//             onSelectionChanged: (selection) {
//               setState(() {
//                 _currentSelection = selection;
//               });
//             },
//             decoration: InputDecoration(
//               contentPadding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
//               filled: true,
//               fillColor: const Color(0xff0a0203),
//               focusedBorder: OutlineInputBorder(
//                 borderSide: const BorderSide(color: Color(0xFFab7421)),
//                 borderRadius: BorderRadius.circular(0),
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderSide: const BorderSide(color: Color(0xffd3d3d3)),
//                 borderRadius: BorderRadius.circular(0),
//               ),
//             ),
//           ),
//         ),
        
//         // Formatted preview
//         Container(
//           padding: const EdgeInsets.all(8.0),
//           color: const Color(0xff0a0203),
//           child: ValueListenableBuilder<String>(
//             valueListenable: _formattedText,
//             builder: (context, value, child) {
//               return Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: RichText(
//                   text: _buildFormattedText(value),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     _textController.dispose();
//     super.dispose();
//   }
// }