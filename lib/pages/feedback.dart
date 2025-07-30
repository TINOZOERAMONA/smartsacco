// // ignore_for_file: use_build_context_synchronously

// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:google_fonts/google_fonts.dart';

// //categories og feedback classification
// enum FeedbackCategory {
//   general,
//   account,
//   loan,
//   shares,
//   complaint,
//   suggestion
// }

// //feedback submission page for SACCO members
// class SaccoFeedbackPage extends StatefulWidget {
//   const SaccoFeedbackPage({super.key});

//   @override
//   State<SaccoFeedbackPage> createState() => _SaccoFeedbackPageState();
// }

// class _SaccoFeedbackPageState extends State<SaccoFeedbackPage> {
//    // Form and field controllers
//   final _formKey = GlobalKey<FormState>();
//   final _subjectController = TextEditingController();
//   final _messageController = TextEditingController();
//   final _memberIdController = TextEditingController();

  
//   // Form state variables
//   FeedbackCategory _selectedCategory = FeedbackCategory.general;
//   bool _isSubmitting = false;
//   final List<PlatformFile> _attachments = [];

//   @override
//   void dispose() {
//     // Clean up controllers when widget is disposed
//     _subjectController.dispose();
//     _messageController.dispose();
//     _memberIdController.dispose();
//     super.dispose();
//   }

//    // Opens file picker for attachments
//   Future<void> _pickFiles() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         allowMultiple: true,
//         type: FileType.custom,
//         allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg'],
//       );

//       if (result != null) {
//         setState(() => _attachments.addAll(result.files));
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error selecting files: $e')),
//       );
//     }
//   }

  
//   // Handles form submission
//   Future<void> _submitFeedback() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isSubmitting = true);

//     try {
//       // Simulate network delay
//       await Future.delayed(const Duration(seconds: 2));
 
//     // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Feedback submitted successfully!')),
//       );
//       _clearForm();
//     } catch (e) {
//       // Handle submission errors
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error submitting feedback: $e')),
//       );
//     } finally {
//       setState(() => _isSubmitting = false);
//     }
//   }
// // Resets the form to initial state
//   void _clearForm() {
//     _subjectController.clear();
//     _messageController.clear();
//     setState(() {
//       _selectedCategory = FeedbackCategory.general;
//       _attachments.clear();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Provide Feedback',
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//                  // Header section
//               Text(
//                 'We value your feedback',
//                 style: GoogleFonts.poppins(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Please share your thoughts, questions or concerns with us',
//                 style: GoogleFonts.poppins(
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               // Member ID field
//               TextFormField(
//                 controller: _memberIdController,
//                 decoration: const InputDecoration(
//                   labelText: 'Member ID',
//                   prefixIcon: Icon(Icons.person),
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your member ID';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<FeedbackCategory>(
//                 value: _selectedCategory,
//                 decoration: const InputDecoration(
//                   labelText: 'Category',
//                   prefixIcon: Icon(Icons.category),
//                   border: OutlineInputBorder(),
//                 ),
//                 items: FeedbackCategory.values.map((category) {
//                   return DropdownMenuItem(
//                     value: category,
//                     child: Text(_formatCategoryName(category)),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   if (value != null) {
//                     setState(() => _selectedCategory = value);
//                   }
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _subjectController,
//                 decoration: const InputDecoration(
//                   labelText: 'Subject',
//                   prefixIcon: Icon(Icons.title),
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter a subject';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _messageController,
//                 decoration: const InputDecoration(
//                   labelText: 'Your Message',
//                   prefixIcon: Icon(Icons.message),
//                   border: OutlineInputBorder(),
//                   alignLabelWithHint: true,
//                 ),
//                 maxLines: 5,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your message';
//                   }
//                   if (value.length < 20) {
//                     return 'Please provide more details (at least 20 characters)';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Attachments (optional)',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               OutlinedButton.icon(
//                 icon: const Icon(Icons.attach_file),
//                 label: const Text('Add Files'),
//                 onPressed: _pickFiles,
//               ),
//               if (_attachments.isNotEmpty) ...[
//                 const SizedBox(height: 8),
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: _attachments.map((file) => Chip(
//                     label: Text(file.name),
//                     deleteIcon: const Icon(Icons.close, size: 18),
//                     onDeleted: () => setState(() => _attachments.remove(file)),
//                   )).toList(),
//                 ),
//               ],
//               const SizedBox(height: 32),
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: _isSubmitting ? null : _submitFeedback,
//                   style: ElevatedButton.styleFrom(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: _isSubmitting
//                       ? const CircularProgressIndicator()
//                       : Text(
//                           'SUBMIT FEEDBACK',
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   String _formatCategoryName(FeedbackCategory category) {
//     switch (category) {
//       case FeedbackCategory.general:
//         return 'General Inquiry';
//       case FeedbackCategory.account:
//         return 'Account Issue';
//       case FeedbackCategory.loan:
//         return 'Loan Service';
//       case FeedbackCategory.shares:
//         return 'Shares & Dividends';
//       case FeedbackCategory.complaint:
//         return 'Complaint';
//       case FeedbackCategory.suggestion:
//         return 'Suggestion';
//     }
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:google_fonts/google_fonts.dart';

// enum FeedbackCategory {
//   general,
//   account,
//   loan,
//   shares,
//   complaint,
//   suggestion
// }

// class SaccoFeedbackPage extends StatefulWidget {
//   const SaccoFeedbackPage({super.key});

//   @override
//   State<SaccoFeedbackPage> createState() => _SaccoFeedbackPageState();
// }

// class _SaccoFeedbackPageState extends State<SaccoFeedbackPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _subjectController = TextEditingController();
//   final _messageController = TextEditingController();
//   final _memberIdController = TextEditingController();

//   FeedbackCategory _selectedCategory = FeedbackCategory.general;
//   bool _isSubmitting = false;
//   final List<PlatformFile> _attachments = [];

//   @override
//   void dispose() {
//     _subjectController.dispose();
//     _messageController.dispose();
//     _memberIdController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickFiles() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         allowMultiple: true,
//         type: FileType.custom,
//         allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg'],
//       );

//       if (result != null) {
//         setState(() => _attachments.addAll(result.files));
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error selecting files: $e')),
//       );
//     }
//   }

//   Future<void> _submitFeedback() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isSubmitting = true);

//     try {
//       await Future.delayed(const Duration(seconds: 2));
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Feedback submitted successfully!')),
//       );
//       _clearForm();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error submitting feedback: $e')),
//       );
//     } finally {
//       setState(() => _isSubmitting = false);
//     }
//   }

//   void _clearForm() {
//     _subjectController.clear();
//     _messageController.clear();
//     setState(() {
//       _selectedCategory = FeedbackCategory.general;
//       _attachments.clear();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Provide Feedback',
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         elevation: 0,
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header with icon
//               Center(
//                 child: Column(
//                   children: [
//                     Icon(
//                       Icons.feedback,
//                       size: 48,
//                       color: theme.primaryColor,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'We Value Your Feedback',
//                       style: GoogleFonts.poppins(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Please share your thoughts, questions or concerns with us. '
//                 'Your feedback helps us improve our services.',
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 32),

//               // Form fields with improved styling
//               _buildTextField(
//                 controller: _memberIdController,
//                 label: 'Member ID',
//                 icon: Icons.person_outline,
//                 validator: (value) =>
//                     value?.isEmpty ?? true ? 'Please enter your member ID' : null,
//               ),

//               const SizedBox(height: 20),
              
//               // Enhanced dropdown
//               InputDecorator(
//                 decoration: InputDecoration(
//                   labelText: 'Category',
//                   prefixIcon: Icon(Icons.category_outlined),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 12),
//                 ),
//                 child: DropdownButtonHideUnderline(
//                   child: DropdownButton<FeedbackCategory>(
//                     value: _selectedCategory,
//                     isExpanded: true,
//                     icon: const Icon(Icons.arrow_drop_down),
//                     items: FeedbackCategory.values.map((category) {
//                       return DropdownMenuItem(
//                         value: category,
//                         child: Text(
//                           _formatCategoryName(category),
//                           style: GoogleFonts.poppins(),
//                         ),
//                       );
//                     }).toList(),
//                     onChanged: (value) {
//                       if (value != null) {
//                         setState(() => _selectedCategory = value);
//                       }
//                     },
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 20),
              
//               _buildTextField(
//                 controller: _subjectController,
//                 label: 'Subject',
//                 icon: Icons.title_outlined,
//                 validator: (value) =>
//                     value?.isEmpty ?? true ? 'Please enter a subject' : null,
//               ),

//               const SizedBox(height: 20),
              
//               // Message field with character counter
//               TextFormField(
//                 controller: _messageController,
//                 decoration: InputDecoration(
//                   labelText: 'Your Message',
//                   prefixIcon: const Icon(Icons.message_outlined),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   alignLabelWithHint: true,
//                   counterText: '${_messageController.text.length}/500',
//                 ),
//                 maxLines: 5,
//                 maxLength: 500,
//                 buildCounter: (context,
//                     {required currentLength, required isFocused, maxLength}) {
//                   return Text(
//                     '$currentLength/$maxLength',
//                     style: GoogleFonts.poppins(
//                       color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
//                     ),
//                   );
//                 },
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your message';
//                   }
//                   if (value.length < 20) {
//                     return 'Please provide more details (at least 20 characters)';
//                   }
//                   return null;
//                 },
//               ),

//               const SizedBox(height: 24),
              
//               // Attachments section
//               Text(
//                 'ATTACHMENTS (OPTIONAL)',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w500,
//                   fontSize: 12,
//                   letterSpacing: 1,
//                   color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 8),
//               OutlinedButton.icon(
//                 icon: const Icon(Icons.attach_file),
//                 label: const Text('Add Files'),
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   side: BorderSide(
//                     color: isDarkMode ? Colors.black54 : Colors.grey[400]!,
//                   ),
//                 ),
//                 onPressed: _pickFiles,
//               ),
              
//               if (_attachments.isNotEmpty) ...[
//                 const SizedBox(height: 16),
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: _attachments.map((file) => Chip(
//                     label: Text(
//                       file.name,
//                       style: GoogleFonts.poppins(fontSize: 12),
//                     ),
//                     deleteIcon: const Icon(Icons.close, size: 16),
//                     onDeleted: () => setState(() => _attachments.remove(file)),
//                   )).toList(),
//                 ),
//               ],

//               const SizedBox(height: 32),
              
//               // Submit button with loading state
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: _isSubmitting ? null : _submitFeedback,
//                   style: ElevatedButton.styleFrom(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     elevation: 2,
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                   ),
//                   child: _isSubmitting
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : Text(
//                           'SUBMIT FEEDBACK',
//                           style: GoogleFonts.poppins(
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 0.5,
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     required String? Function(String?) validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//       validator: validator,
//     );
//   }

//   String _formatCategoryName(FeedbackCategory category) {
//     return category.toString().split('.').last[0].toUpperCase() +
//         category.toString().split('.').last.substring(1);
//   }
// }

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

enum FeedbackCategory {
  general,
  account,
  loan,
  shares,
  complaint,
  suggestion
}

class SaccoFeedbackPage extends StatefulWidget {
  const SaccoFeedbackPage({super.key});

  @override
  State<SaccoFeedbackPage> createState() => _SaccoFeedbackPageState();
}

class _SaccoFeedbackPageState extends State<SaccoFeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _memberIdController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  FeedbackCategory _selectedCategory = FeedbackCategory.general;
  bool _isSubmitting = false;
  final List<PlatformFile> _attachments = [];

  @override
  void dispose() {
    _fullNameController.dispose();
    _memberIdController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg'],
      );

      if (result != null) {
        setState(() => _attachments.addAll(result.files));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting files: $e')),
      );
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await Future.delayed(const Duration(seconds: 2));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _fullNameController.clear();
    _memberIdController.clear();
    _subjectController.clear();
    _messageController.clear();
    setState(() {
      _selectedCategory = FeedbackCategory.general;
      _attachments.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Provide Feedback',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.feedback,
                        size: 48,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We Value Your Feedback',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please share your thoughts, questions or concerns with us. '
                'Your feedback helps us improve our services.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Full Name field
              _buildTextField(
                controller: _fullNameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter your full name' : null,
              ),
              const SizedBox(height: 20),

              // Member ID field
              _buildTextField(
                controller: _memberIdController,
                label: 'Member ID',
                icon: Icons.badge_outlined,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter your member ID' : null,
              ),
              const SizedBox(height: 20),
              
              // Enhanced dropdown
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<FeedbackCategory>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                    items: FeedbackCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(
                          _formatCategoryName(category),
                          style: GoogleFonts.poppins(),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Subject field
              _buildTextField(
                controller: _subjectController,
                label: 'Subject',
                icon: Icons.title_outlined,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a subject' : null,
              ),
              const SizedBox(height: 20),
              
              // Message field with character counter
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Your Message',
                  prefixIcon: Icon(Icons.message_outlined, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  alignLabelWithHint: true,
                  counterText: '${_messageController.text.length}/500',
                ),
                maxLines: 5,
                maxLength: 500,
                buildCounter: (context,
                    {required currentLength, required isFocused, maxLength}) {
                  return Text(
                    '$currentLength/$maxLength',
                    style: GoogleFonts.poppins(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  );
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your message';
                  }
                  if (value.length < 20) {
                    return 'Please provide more details (at least 20 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Attachments section
              Text(
                'ATTACHMENTS (OPTIONAL)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  letterSpacing: 1,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: Icon(Icons.attach_file, color: primaryColor),
                label: Text(
                  'Add Files',
                  style: GoogleFonts.poppins(color: primaryColor),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: primaryColor),
                ),
                onPressed: _pickFiles,
              ),
              
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _attachments.map((file) => Chip(
                    label: Text(
                      file.name,
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _attachments.remove(file)),
                    backgroundColor: primaryColor.withOpacity(0.1),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 32),
              
              // Submit button with loading state
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'SUBMIT FEEDBACK',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  String _formatCategoryName(FeedbackCategory category) {
    return category.toString().split('.').last[0].toUpperCase() +
        category.toString().split('.').last.substring(1);
  }
}



